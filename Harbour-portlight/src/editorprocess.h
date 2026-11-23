#ifndef EDITORPROCESS_H
#define EDITORPROCESS_H

#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QVariantMap>

class QSocketNotifier;

class EditorProcess : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit EditorProcess(QObject *parent = nullptr);

    bool running() const;

    Q_INVOKABLE bool start(const QString &title, const QString &content,
                           const QString &status);
    Q_INVOKABLE bool send(const QString &type, const QVariantMap &data = QVariantMap());

signals:
    void runningChanged();
    void messageReceived(const QString &type, const QVariantMap &data);
    void processError(const QString &error);
    void finished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    void readOutput();
    void readErrors(bool flush = false);
    void writeMessage(const QVariantMap &message);

    QProcess m_process;
    QVariantMap m_initialMessage;
    QQueue<QVariantMap> m_pendingMessages;
    QByteArray m_output;
    QByteArray m_errorOutput;
    bool m_helperReady = false;
};

class EditorChannel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY editorDataChanged)
    Q_PROPERTY(QString content READ content NOTIFY editorDataChanged)
    Q_PROPERTY(QString status READ status NOTIFY editorDataChanged)

public:
    explicit EditorChannel(QObject *parent = nullptr);

    QString title() const;
    QString content() const;
    QString status() const;

    Q_INVOKABLE void send(const QString &type, const QVariantMap &data = QVariantMap());

signals:
    void editorDataChanged();
    void commandReceived(const QString &type, const QVariantMap &data);

private slots:
    void readInput();

private:
    void processLine(const QByteArray &line);

    QSocketNotifier *m_notifier;
    QByteArray m_input;
    QString m_title;
    QString m_content;
    QString m_status;
};

#endif
