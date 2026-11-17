import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Page {
    id: page
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
            width: page.width
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
                checked: vault.autoSave
                onCheckedChanged: vault.autoSave = checked
            }
            Slider {
                width: parent.width
                label: "Save delay"
                minimumValue: 0
                maximumValue: page.saveDelays.length - 1
                stepSize: 1
                value: Math.max(0, page.saveDelays.indexOf(vault.saveDelay))
                valueText: page.saveDelayLabel(page.saveDelays[Math.round(value)])
                enabled: vault.autoSave
                onValueChanged: vault.saveDelay = page.saveDelays[Math.round(value)]
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: page.statusText
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
                    page.statusText = "Choose an accessible folder"
                }
            }
        }
    }
}
