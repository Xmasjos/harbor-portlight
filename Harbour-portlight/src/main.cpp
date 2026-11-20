#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>

#include <sailfishapp.h>

#include "vaultbackend.h"

Q_LOGGING_CATEGORY(lcApplication, "portlight.app")

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    if (!qEnvironmentVariableIsSet("QT_LOGGING_RULES")
            && !qEnvironmentVariableIsSet("QT_LOGGING_CONF")) {
#ifdef QT_NO_DEBUG
        QLoggingCategory::setFilterRules(QStringLiteral("*.debug=false\n*.info=false\n*.warning=false"));
#else
        QLoggingCategory::setFilterRules(QStringLiteral("*.debug=false\n*.info=true"));
#endif
    }

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    VaultBackend vault;

    view->rootContext()->setContextProperty(QStringLiteral("vault"), &vault);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/Harbour-portlight.qml")));
    view->show();
    qCDebug(lcApplication) << "Application started";

    return app->exec();
}
