import QtQuick 2.5
import Sailfish.Silica 1.0

Page {
    id: imagePage
    allowedOrientations: Orientation.All
    property string imagePath: ""
    property string imageSource: ""

    Column {
        anchors.fill: parent
        PageHeader { title: imagePage.imagePath.substring(imagePage.imagePath.lastIndexOf("/") + 1) }
        Image {
            id: image
            width: parent.width
            height: parent.height - y
            source: imagePage.imageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: false
            autoTransform: true
            sourceSize.width: Screen.width
            sourceSize.height: Screen.height
            Label {
                anchors.centerIn: parent
                visible: parent.status === Image.Error
                text: "Unable to display image"
                color: Theme.secondaryColor
            }
        }
    }

    BusyLabel {
        anchors.centerIn: parent
        visible: image.status === Image.Loading
        text: "Loading image"
        running: visible
    }
}
