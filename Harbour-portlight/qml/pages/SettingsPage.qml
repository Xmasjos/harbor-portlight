import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Page {
    allowedOrientations: Orientation.All
    id: settingsPage
    property var applicationWindow
    property string statusText: ""
    property var saveDelays: [0, 300, 500, 1000, 2000, 3000, 5000, 10000, 20000, 30000]

    function saveDelayLabel(milliseconds) {
        if (milliseconds === 0) return "Instant"
        if (milliseconds < 1000) return milliseconds + " ms"
        return (milliseconds / 1000) + " s"
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: settingsPage.width
            PageHeader { title: "Settings" }

            SectionHeader { text: "Vault" }
            ValueButton {
                width: parent.width
                label: "Vault folder"
                value: vault.vaultPath
                onClicked: pageStack.push(folderPicker)
            }

            SectionHeader { text: "Notes" }
            TextSwitch {
                text: "Save notes automatically"
                description: "Save edits after a short pause"
                automaticCheck: false
                checked: settingsPage.applicationWindow.autoSave
                onClicked: settingsPage.applicationWindow.autoSave = !settingsPage.applicationWindow.autoSave
            }
            Slider {
                width: parent.width
                label: "Save delay"
                minimumValue: 0
                maximumValue: settingsPage.saveDelays.length - 1
                stepSize: 1
                value: Math.max(0, settingsPage.saveDelays.indexOf(settingsPage.applicationWindow.saveDelay))
                valueText: settingsPage.saveDelayLabel(settingsPage.saveDelays[Math.round(value)])
                enabled: settingsPage.applicationWindow.autoSave
                onReleased: settingsPage.applicationWindow.saveDelay = settingsPage.saveDelays[Math.round(value)]
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: settingsPage.statusText
                visible: text.length > 0
                color: Theme.highlightColor
            }
        }
        VerticalScrollDecorator {}
    }

    Component {
        id: folderPicker
        FolderPickerDialog {
            title: "Choose vault folder"
            onAccepted: {
                if (!vault.setVaultPath(selectedPath)) {
                    settingsPage.statusText = "Choose an accessible folder"
                } else {
                    settingsPage.applicationWindow.vaultPath = vault.vaultPath
                }
            }
        }
    }
}
