#include "vaultbackend.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QSaveFile>
#include <QVariantList>

namespace {
bool isTextNote(const QFileInfo &file, const QMimeDatabase &mimeDatabase)
{
    const QString suffix = file.suffix().toLower();
    if (suffix == QStringLiteral("md") || suffix == QStringLiteral("markdown")) {
        return true;
    }
    const QString mimeType = mimeDatabase.mimeTypeForFile(file.fileName(), QMimeDatabase::MatchExtension).name();
    if (mimeType.startsWith(QStringLiteral("text/"))
            || mimeType == QStringLiteral("application/json")
            || mimeType == QStringLiteral("application/xml")
            || mimeType.endsWith(QStringLiteral("+json"))
            || mimeType.endsWith(QStringLiteral("+xml"))) {
        return true;
    }
    return mimeType == QStringLiteral("application/octet-stream")
            && (file.size() == 0
                || mimeDatabase.mimeTypeForFile(file.filePath(), QMimeDatabase::MatchContent).name()
                        .startsWith(QStringLiteral("text/")));
}

QString safeNotePath(const QString &vaultPath, const QString &relativePath)
{
    const QString cleanedPath = QDir::cleanPath(relativePath);
    if (relativePath.isEmpty() || QDir::isAbsolutePath(relativePath)
            || cleanedPath == QStringLiteral("..")
            || cleanedPath.startsWith(QStringLiteral("../"))
            || QFileInfo(cleanedPath).suffix().isEmpty()) {
        return QString();
    }
    const QString root = QFileInfo(vaultPath).canonicalFilePath();
    const QString path = QFileInfo(QDir(vaultPath).filePath(cleanedPath)).canonicalFilePath();
    return !root.isEmpty() && path.startsWith(root + QDir::separator()) ? path : QString();
}

QString safeDestinationPath(const QString &vaultPath, const QString &relativePath)
{
    const QString cleaned = QDir::cleanPath(relativePath);
    if (relativePath.isEmpty() || QDir::isAbsolutePath(relativePath)
            || cleaned == QStringLiteral("..") || cleaned.startsWith(QStringLiteral("../"))) {
        return QString();
    }
    const QString root = QFileInfo(vaultPath).canonicalFilePath();
    const QString parent = QFileInfo(QDir(vaultPath).filePath(QFileInfo(cleaned).path())).canonicalFilePath();
    if (root.isEmpty() || parent.isEmpty()
            || (parent != root && !parent.startsWith(root + QDir::separator()))) {
        return QString();
    }
    const QString path = QDir(parent).filePath(QFileInfo(cleaned).fileName());
    const QString existing = QFileInfo(path).canonicalFilePath();
    return existing.isEmpty() || existing.startsWith(root + QDir::separator()) ? path : QString();
}

QString safeFolderPath(const QString &vaultPath, const QString &relativePath)
{
    const QString cleaned = QDir::cleanPath(relativePath);
    if (relativePath.isEmpty() || QDir::isAbsolutePath(relativePath)
            || cleaned == QStringLiteral("..") || cleaned.startsWith(QStringLiteral("../"))) {
        return QString();
    }
    const QString root = QFileInfo(vaultPath).canonicalFilePath();
    const QString path = QFileInfo(QDir(vaultPath).filePath(cleaned)).canonicalFilePath();
    return !root.isEmpty() && path.startsWith(root + QDir::separator())
            && QFileInfo(path).isDir() && !QFileInfo(path).isSymLink() ? path : QString();
}

bool copyDirectory(const QString &source, const QString &destination)
{
    if (!QDir().mkdir(destination)) {
        return false;
    }
    const QFileInfoList entries = QDir(source).entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System, QDir::Name);
    for (const QFileInfo &entry : entries) {
        const QString target = QDir(destination).filePath(entry.fileName());
        if (entry.isSymLink()
                || (entry.isDir() ? !copyDirectory(entry.filePath(), target)
                                  : !QFile::copy(entry.filePath(), target))) {
            QDir(destination).removeRecursively();
            return false;
        }
    }
    return true;
}
}

VaultBackend::VaultBackend(QObject *parent)
    : QObject(parent),
      m_vaultPath(QDir::home().filePath(QStringLiteral("Documents/Obsidian")))
{
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &VaultBackend::folderChanged);
}

void VaultBackend::watchFolder(const QString &relativeFolder)
{
    m_watcher.removePaths(m_watcher.directories());
    const QVariantMap result = listVaultEntries(relativeFolder);
    if (!result.value(QStringLiteral("ok")).toBool()) {
        return;
    }
    const QString folder = relativeFolder.isEmpty()
            ? QFileInfo(m_vaultPath).canonicalFilePath()
            : QFileInfo(QDir(m_vaultPath).filePath(QDir::cleanPath(relativeFolder))).canonicalFilePath();
    if (!folder.isEmpty()) {
        m_watcher.addPath(folder);
    }
}

QVariantMap VaultBackend::listVaultEntries(const QString &relativeFolder) const
{
    const QString cleanedFolder = QDir::cleanPath(relativeFolder);
    if (QDir::isAbsolutePath(relativeFolder) || cleanedFolder == QStringLiteral("..")
            || cleanedFolder.startsWith(QStringLiteral("../"))) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid folder path")}};
    }

    const QString root = QFileInfo(m_vaultPath).canonicalFilePath();
    const QString folderPath = relativeFolder.isEmpty()
            ? root : QFileInfo(QDir(m_vaultPath).filePath(cleanedFolder)).canonicalFilePath();
    if (root.isEmpty() || folderPath.isEmpty()
            || (folderPath != root && !folderPath.startsWith(root + QDir::separator()))
            || !QFileInfo(folderPath).isDir()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Folder is outside the vault or does not exist")}};
    }

    const QDir folder(folderPath);
    if (!folder.isReadable()) {
        return {{QStringLiteral("ok"), false},
                {QStringLiteral("error"), QStringLiteral("Folder is not readable")}};
    }

    QVariantList entries;
    const QFileInfoList folders = folder.entryInfoList(
            QDir::Dirs | QDir::NoDotAndDotDot | QDir::Readable | QDir::NoSymLinks, QDir::Name);
    for (const QFileInfo &entry : folders) {
        if (entry.fileName().compare(QStringLiteral(".obsidian"), Qt::CaseInsensitive) == 0) {
            continue;
        }
        entries.append(QVariantMap{
            {QStringLiteral("type"), QStringLiteral("folder")},
            {QStringLiteral("name"), entry.fileName()},
            {QStringLiteral("path"), QDir(root).relativeFilePath(entry.filePath())}
        });
    }

    const QFileInfoList files = folder.entryInfoList(
            QDir::Files | QDir::Readable | QDir::NoSymLinks, QDir::Name);
    const QMimeDatabase mimeDatabase;
    for (const QFileInfo &entry : files) {
        if (!isTextNote(entry, mimeDatabase)) {
            continue;
        }
        entries.append(QVariantMap{
            {QStringLiteral("type"), QStringLiteral("note")},
            {QStringLiteral("name"), entry.fileName()},
            {QStringLiteral("path"), QDir(root).relativeFilePath(entry.filePath())}
        });
    }

    return {{QStringLiteral("ok"), true}, {QStringLiteral("entries"), entries}};
}

QVariantMap VaultBackend::searchNotes(const QString &query) const
{
    const QString needle = query.trimmed();
    if (needle.isEmpty()) {
        return {{QStringLiteral("ok"), true}, {QStringLiteral("matches"), QVariantList()}};
    }

    const QDir vaultDir(m_vaultPath);
    if (!vaultDir.exists() || !vaultDir.isReadable()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Vault folder is not readable")}};
    }

    QVariantList matches;
    // ponytail: scan files per settled query; add an index only if this becomes slow on the target phone.
    const QMimeDatabase mimeDatabase;
    QDirIterator it(m_vaultPath,
                    QStringList() << QStringLiteral("*"),
                    QDir::Files | QDir::Readable | QDir::NoSymLinks,
                    QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString path = it.next();
        const QString relativePath = vaultDir.relativeFilePath(path);
        if (relativePath.startsWith(QStringLiteral(".obsidian/"), Qt::CaseInsensitive)
                || relativePath.contains(QStringLiteral("/.obsidian/"), Qt::CaseInsensitive)) {
            continue;
        }
        if (!isTextNote(QFileInfo(path), mimeDatabase)) {
            continue;
        }
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }
        const QString content = QString::fromUtf8(file.readAll());
        const int matchAt = content.indexOf(needle, 0, Qt::CaseInsensitive);
        const bool pathMatches = relativePath.contains(needle, Qt::CaseInsensitive);
        if (matchAt < 0 && !pathMatches) {
            continue;
        }

        QString excerpt;
        if (matchAt >= 0) {
            const int start = qMax(0, matchAt - 50);
            excerpt = content.mid(start, needle.length() + 120).simplified();
            if (start > 0) {
                excerpt.prepend(QStringLiteral("…"));
            }
            if (start + needle.length() + 120 < content.length()) {
                excerpt.append(QStringLiteral("…"));
            }
        } else {
            excerpt = QStringLiteral("Title match");
        }
        matches.append(QVariantMap{
            {QStringLiteral("path"), relativePath},
            {QStringLiteral("excerpt"), excerpt}
        });
    }
    return {{QStringLiteral("ok"), true}, {QStringLiteral("matches"), matches}};
}

QVariantMap VaultBackend::readNote(const QString &relativePath) const
{
    const QString path = safeNotePath(m_vaultPath, relativePath);
    if (path.isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Note is outside the vault")}};
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), file.errorString()}};
    }

    return {{QStringLiteral("ok"), true}, {QStringLiteral("content"), QString::fromUtf8(file.readAll())}};
}

QVariantMap VaultBackend::writeNote(const QString &relativePath, const QString &content) const
{
    const QString path = safeDestinationPath(m_vaultPath, relativePath);
    if (path.isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Note is outside the vault")}};
    }
    QSaveFile file(path);
    const QByteArray bytes = content.toUtf8();
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)
            || file.write(bytes) != bytes.size() || !file.commit()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), file.errorString()}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::createNote(const QString &relativePath, const QString &content) const
{
    const QString path = safeDestinationPath(m_vaultPath, relativePath);
    if (path.isEmpty() || QFileInfo(path).suffix().isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid note path")}};
    }
    if (QFileInfo::exists(path)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("A note with that name already exists")}};
    }
    QSaveFile file(path);
    const QByteArray bytes = content.toUtf8();
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)
            || file.write(bytes) != bytes.size() || !file.commit()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), file.errorString()}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::createFolder(const QString &relativePath) const
{
    const QString cleaned = QDir::cleanPath(relativePath);
    if (relativePath.isEmpty() || QDir::isAbsolutePath(relativePath)
            || cleaned == QStringLiteral("..") || cleaned.startsWith(QStringLiteral("../"))) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid folder name")}};
    }
    const QString root = QFileInfo(m_vaultPath).canonicalFilePath();
    const QString parent = QFileInfo(QDir(m_vaultPath).filePath(QFileInfo(cleaned).path())).canonicalFilePath();
    if (root.isEmpty() || parent.isEmpty()
            || (parent != root && !parent.startsWith(root + QDir::separator()))) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Folder is outside the vault")}};
    }
    const QString path = QDir(parent).filePath(QFileInfo(cleaned).fileName());
    if (QFileInfo::exists(path) || !QDir().mkdir(path)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Folder already exists or could not be created")}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::deleteFolder(const QString &relativePath) const
{
    const QString path = safeFolderPath(m_vaultPath, relativePath);
    if (path.isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid folder path")}};
    }
    if (!QDir(path).removeRecursively()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Folder could not be deleted")}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::copyFolder(const QString &relativePath, const QString &destinationPath) const
{
    const QString source = safeFolderPath(m_vaultPath, relativePath);
    const QString destination = safeDestinationPath(m_vaultPath, destinationPath);
    const QString sourcePrefix = source + QDir::separator();
    if (source.isEmpty() || destination.isEmpty()
            || destination == source || destination.startsWith(sourcePrefix)
            || QFileInfo::exists(destination)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid or existing destination folder")}};
    }
    if (!copyDirectory(source, destination)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Folder could not be copied")}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::moveFolder(const QString &relativePath, const QString &destinationPath) const
{
    const QString source = safeFolderPath(m_vaultPath, relativePath);
    const QString destination = safeDestinationPath(m_vaultPath, destinationPath);
    const QString sourcePrefix = source + QDir::separator();
    if (source.isEmpty() || destination.isEmpty()
            || destination == source || destination.startsWith(sourcePrefix)
            || QFileInfo::exists(destination)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid or existing destination folder")}};
    }
    if (!QDir().rename(source, destination)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Folder could not be moved")}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::deleteNote(const QString &relativePath) const
{
    const QString path = safeNotePath(m_vaultPath, relativePath);
    if (path.isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Note is outside the vault")}};
    }
    if (!QFile::remove(path)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Note could not be deleted")}};
    }
    return {{QStringLiteral("ok"), true}};
}

QVariantMap VaultBackend::copyNote(const QString &relativePath, const QString &destinationPath) const
{
    const QString source = safeNotePath(m_vaultPath, relativePath);
    const QString destination = safeDestinationPath(m_vaultPath, destinationPath);
    if (source.isEmpty() || destination.isEmpty() || QFileInfo(destination).suffix().isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid note path")}};
    }
    if (QFileInfo::exists(destination) || !QFile::copy(source, destination)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Destination exists or note could not be copied")}};
    }
    return {{QStringLiteral("ok"), true}, {QStringLiteral("path"), QDir(m_vaultPath).relativeFilePath(destination)}};
}

QVariantMap VaultBackend::moveNote(const QString &relativePath, const QString &destinationPath) const
{
    const QString source = safeNotePath(m_vaultPath, relativePath);
    const QString destination = safeDestinationPath(m_vaultPath, destinationPath);
    if (source.isEmpty() || destination.isEmpty() || QFileInfo(destination).suffix().isEmpty()) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Invalid note path")}};
    }
    if (QFileInfo::exists(destination) || !QFile::rename(source, destination)) {
        return {{QStringLiteral("ok"), false}, {QStringLiteral("error"), QStringLiteral("Destination exists or note could not be moved")}};
    }
    return {{QStringLiteral("ok"), true}, {QStringLiteral("path"), QDir(m_vaultPath).relativeFilePath(destination)}};
}
