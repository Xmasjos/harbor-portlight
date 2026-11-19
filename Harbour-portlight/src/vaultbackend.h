#ifndef VAULTBACKEND_H
#define VAULTBACKEND_H

#include <QObject>
#include <QFileSystemWatcher>
#include <QVariantMap>

class VaultBackend : public QObject
{
    Q_OBJECT

public:
    explicit VaultBackend(QObject *parent = nullptr);

    Q_PROPERTY(QString vaultPath READ vaultPath NOTIFY vaultPathChanged)

    QString vaultPath() const;
    Q_INVOKABLE bool setVaultPath(const QString &path);

    Q_INVOKABLE void watchFolder(const QString &relativeFolder);
    Q_INVOKABLE void watchNote(const QString &relativePath);
    Q_INVOKABLE void unwatchNote();

    Q_INVOKABLE QVariantMap listVaultEntries(const QString &relativeFolder) const;
    Q_INVOKABLE QVariantMap searchNotes(const QString &query) const;
    Q_INVOKABLE QVariantMap readNote(const QString &relativePath) const;
    Q_INVOKABLE QString imageUrl(const QString &relativePath) const;
    Q_INVOKABLE QVariantMap writeNote(const QString &relativePath, const QString &content,
                                      const QString &expectedContent) const;
    Q_INVOKABLE QVariantMap createNote(const QString &relativePath, const QString &content) const;
    Q_INVOKABLE QVariantMap createFolder(const QString &relativePath) const;
    Q_INVOKABLE QVariantMap deleteFolder(const QString &relativePath) const;
    Q_INVOKABLE QVariantMap copyFolder(const QString &relativePath, const QString &destinationPath) const;
    Q_INVOKABLE QVariantMap moveFolder(const QString &relativePath, const QString &destinationPath) const;
    Q_INVOKABLE QVariantMap deleteNote(const QString &relativePath) const;
    Q_INVOKABLE QVariantMap copyNote(const QString &relativePath, const QString &destinationPath) const;
    Q_INVOKABLE QVariantMap moveNote(const QString &relativePath, const QString &destinationPath) const;

private:
    QString m_vaultPath;
    QString m_watchedNotePath;
    QFileSystemWatcher m_watcher;

signals:
    void folderChanged();
    void noteChanged(const QString &relativePath);
    void vaultPathChanged();
};

#endif // VAULTBACKEND_H
