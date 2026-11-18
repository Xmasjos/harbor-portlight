import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: errorPage
    allowedOrientations: Orientation.All
    property var applicationWindow
    property string statusText: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        Column {
            id: column
            width: errorPage.width
            PageHeader { title: "Quick note unavailable" }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: errorPage.statusText
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"), {
                    applicationWindow: errorPage.applicationWindow
                })
            }
        }
    }
}
