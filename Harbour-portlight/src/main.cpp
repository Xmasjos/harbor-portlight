#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>

#include <sailfishapp.h>

#include "vaultbackend.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    VaultBackend vault;

    view->rootContext()->setContextProperty(QStringLiteral("vault"), &vault);
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/Harbour-portlight.qml")));
    view->show();

    return app->exec();
}
