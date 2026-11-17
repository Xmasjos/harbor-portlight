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
    Q_PROPERTY(bool autoSave READ autoSave WRITE setAutoSave NOTIFY autoSaveChanged)
    Q_PROPERTY(int saveDelay READ saveDelay WRITE setSaveDelay NOTIFY saveDelayChanged)
    Q_PROPERTY(bool showUnsupportedFiles READ showUnsupportedFiles WRITE setShowUnsupportedFiles NOTIFY showUnsupportedFilesChanged)

    QString vaultPath() const;
    bool autoSave() const;
    void setAutoSave(bool enabled);
    int saveDelay() const;
    void setSaveDelay(int seconds);
    bool showUnsupportedFiles() const;
    void setShowUnsupportedFiles(bool show);
    Q_INVOKABLE bool setVaultPath(const QString &path);

    Q_INVOKABLE void watchFolder(const QString &relativeFolder);

    Q_INVOKABLE QVariantMap listVaultEntries(const QString &relativeFolder) const;
    Q_INVOKABLE QVariantMap searchNotes(const QString &query) const;
    Q_INVOKABLE QVariantMap readNote(const QString &relativePath) const;
    Q_INVOKABLE QVariantMap writeNote(const QString &relativePath, const QString &content) const;
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
    QFileSystemWatcher m_watcher;

signals:
    void folderChanged();
    void vaultPathChanged();
    void autoSaveChanged();
    void saveDelayChanged();
    void showUnsupportedFilesChanged();
};

#endif // VAULTBACKEND_H
