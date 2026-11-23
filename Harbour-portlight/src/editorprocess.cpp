#include "editorprocess.h"

#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QLoggingCategory>
#include <QSocketNotifier>

#include <cerrno>
#include <unistd.h>

Q_LOGGING_CATEGORY(lcEditorProcess, "portlight.editorprocess")

EditorProcess::EditorProcess(QObject *parent)
    : QObject(parent)
{
    connect(&m_process, &QProcess::started, this, [this]() {
        writeMessage(m_initialMessage);
        while (!m_pendingMessages.isEmpty()) {
            writeMessage(m_pendingMessages.dequeue());
        }
        emit runningChanged();
    });
    connect(&m_process, &QProcess::readyReadStandardOutput,
            this, &EditorProcess::readOutput);
    connect(&m_process, &QProcess::readyReadStandardError,
            this, [this]() { readErrors(); });
    connect(&m_process,
            static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus exitStatus) {
        readOutput();
        readErrors(true);
        qCWarning(lcEditorProcess) << "[DEBUG-helper-exit] code=" << exitCode
                                   << "status=" << exitStatus;
        emit runningChanged();
        emit finished(exitCode, exitStatus);
    });
    connect(&m_process, &QProcess::errorOccurred, this,
            [this](QProcess::ProcessError error) {
        Q_UNUSED(error)
        emit processError(m_process.errorString());
    });
}

bool EditorProcess::running() const
{
    return m_process.state() != QProcess::NotRunning;
}

bool EditorProcess::start(const QString &title, const QString &content,
                          const QString &status)
{
    if (running()) return false;

    m_output.clear();
    m_errorOutput.clear();
    m_pendingMessages.clear();
    m_helperReady = false;
    m_initialMessage = {
        {QStringLiteral("type"), QStringLiteral("init")},
        {QStringLiteral("title"), title},
        {QStringLiteral("content"), content},
        {QStringLiteral("status"), status}
    };
    m_process.start(QCoreApplication::applicationFilePath(),
                    QStringList() << QStringLiteral("--editor-helper"),
                    QIODevice::ReadWrite);
    return true;
}

bool EditorProcess::send(const QString &type, const QVariantMap &data)
{
    if (!running()) return false;
    QVariantMap message = data;
    message.insert(QStringLiteral("type"), type);
    if (m_process.state() == QProcess::Starting) m_pendingMessages.enqueue(message);
    else writeMessage(message);
    return true;
}

void EditorProcess::readOutput()
{
    m_output.append(m_process.readAllStandardOutput());
    int newline = -1;
    while ((newline = m_output.indexOf('\n')) >= 0) {
        const QByteArray line = m_output.left(newline);
        m_output.remove(0, newline + 1);
        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(line, &error);
        if (error.error != QJsonParseError::NoError || !document.isObject()) {
            const QString firstByte = line.isEmpty()
                    ? QStringLiteral("none")
                    : QString::number(static_cast<unsigned char>(line.at(0)), 16);
            if (!m_helperReady) {
                qCWarning(lcEditorProcess) << "[DEBUG-helper-stdout] Startup line length="
                                           << line.size() << "firstByte=0x" << firstByte
                                           << "text=" << QString::fromUtf8(line.left(512))
                                           << "error=" << error.errorString();
            }
            continue;
        }
        const QVariantMap message = document.object().toVariantMap();
        const QString type = message.value(QStringLiteral("type")).toString();
        if (type.isEmpty()) {
            qCWarning(lcEditorProcess) << "Ignoring helper message without a type";
            continue;
        }
        if (type == QStringLiteral("ready")) m_helperReady = true;
        emit messageReceived(type, message);
    }
}

void EditorProcess::readErrors(bool flush)
{
    m_errorOutput.append(m_process.readAllStandardError());
    int newline = -1;
    while ((newline = m_errorOutput.indexOf('\n')) >= 0 || (flush && !m_errorOutput.isEmpty())) {
        const QByteArray line = newline >= 0 ? m_errorOutput.left(newline) : m_errorOutput;
        m_errorOutput.remove(0, newline >= 0 ? newline + 1 : m_errorOutput.size());
        if (!m_helperReady) {
            qCWarning(lcEditorProcess) << "[DEBUG-helper-stderr] Startup:"
                                       << QString::fromLocal8Bit(line.left(512));
        }
    }
}

void EditorProcess::writeMessage(const QVariantMap &message)
{
    const QByteArray line = QJsonDocument::fromVariant(message).toJson(QJsonDocument::Compact)
            + '\n';
    if (m_process.write(line) != line.size()) {
        emit processError(m_process.errorString());
    }
}

EditorChannel::EditorChannel(QObject *parent)
    : QObject(parent),
      m_notifier(new QSocketNotifier(STDIN_FILENO, QSocketNotifier::Read, this))
{
    connect(m_notifier, &QSocketNotifier::activated, this, &EditorChannel::readInput);
}

QString EditorChannel::title() const
{
    return m_title;
}

QString EditorChannel::content() const
{
    return m_content;
}

QString EditorChannel::status() const
{
    return m_status;
}

void EditorChannel::send(const QString &type, const QVariantMap &data)
{
    QVariantMap message = data;
    message.insert(QStringLiteral("type"), type);
    const QByteArray line = QJsonDocument::fromVariant(message).toJson(QJsonDocument::Compact)
            + '\n';
    qint64 written = 0;
    while (written < line.size()) {
        const ssize_t result = ::write(STDOUT_FILENO, line.constData() + written,
                                       size_t(line.size() - written));
        if (result < 0 && errno == EINTR) continue;
        if (result <= 0) {
            qCWarning(lcEditorProcess) << "Unable to write editor helper message";
            return;
        }
        written += result;
    }
}

void EditorChannel::readInput()
{
    char buffer[8192];
    const ssize_t bytesRead = ::read(STDIN_FILENO, buffer, sizeof(buffer));
    if (bytesRead <= 0) {
        m_notifier->setEnabled(false);
        return;
    }
    m_input.append(buffer, int(bytesRead));
    int newline = -1;
    while ((newline = m_input.indexOf('\n')) >= 0) {
        const QByteArray line = m_input.left(newline);
        m_input.remove(0, newline + 1);
        processLine(line);
    }
}

void EditorChannel::processLine(const QByteArray &line)
{
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(line, &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        qCWarning(lcEditorProcess) << "Ignoring invalid parent message:" << error.errorString();
        return;
    }

    const QVariantMap message = document.object().toVariantMap();
    const QString type = message.value(QStringLiteral("type")).toString();
    if (type == QStringLiteral("init") || type == QStringLiteral("update")) {
        const QJsonObject object = document.object();
        if (!object.value(QStringLiteral("title")).isString()
                || !object.value(QStringLiteral("content")).isString()
                || !object.value(QStringLiteral("status")).isString()) {
            qCWarning(lcEditorProcess) << "Ignoring editor update with invalid fields";
            return;
        }
        m_title = message.value(QStringLiteral("title")).toString();
        m_content = message.value(QStringLiteral("content")).toString();
        m_status = message.value(QStringLiteral("status")).toString();
        emit editorDataChanged();
    } else if (type != QStringLiteral("saveResult")
               && type != QStringLiteral("close")) {
        qCWarning(lcEditorProcess) << "Ignoring unknown parent message type:" << type;
        return;
    }
    emit commandReceived(type, message);
}
