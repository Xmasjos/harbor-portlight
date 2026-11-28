import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Page {
    id: vaultsPage
    allowedOrientations: Orientation.All
    property var applicationWindow
    property Component vaultBrowserPageComponent
    property var paths: []
    property string statusText: ""

    function loadPaths() {
        try { paths = JSON.parse(applicationWindow.registeredVaults) }
        catch (error) { paths = [] }
    }

    function savePaths() {
        applicationWindow.registeredVaults = JSON.stringify(paths)
    }

    function vaultName(path) {
        var clean = path.replace(/\\+$/, "").replace(/\/+$/, "")
        return clean.substring(Math.max(clean.lastIndexOf("/"), clean.lastIndexOf("\\")) + 1)
    }

    function openVault(path) {
        if (!vault.setVaultPath(path)) {
            statusText = "This vault is unavailable. Choose another folder or remove it from the list."
            return
        }
        applicationWindow.vaultPath = vault.vaultPath
        pageStack.push(vaultBrowserPageComponent, {
            applicationWindow: applicationWindow,
            vaultBrowserPageComponent: vaultBrowserPageComponent
        })
    }

    function addVault(path) {
        if (!vault.setVaultPath(path)) {
            statusText = "Choose an accessible folder"
            return false
        }
        var canonical = vault.vaultPath
        for (var i = 0; i < paths.length; i++) {
            if (paths[i] === canonical) {
                statusText = "This vault is already in the list"
                return false
            }
        }
        paths = paths.concat([canonical])
        savePaths()
        applicationWindow.vaultPath = canonical
        statusText = ""
        return true
    }

    Component.onCompleted: loadPaths()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: "Add vault"
                visible: vaultsPage.paths.length > 0
                onClicked: pageStack.push(addVaultPicker)
            }
        }

        Column {
            id: column
            width: vaultsPage.width
            spacing: Theme.paddingSmall
            PageHeader { title: "Vaults" }

            Column {
                visible: vaultsPage.paths.length === 0
                width: parent.width
                spacing: Theme.paddingMedium
                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    text: "Add your first vault to start browsing notes"
                    color: Theme.secondaryColor
                    wrapMode: Text.Wrap
                }
                Button {
                    text: "Add your first vault"
                    x: (parent.width - width) / 2
                    onClicked: pageStack.push(firstVaultPicker)
                }
            }

            Repeater {
                model: vaultsPage.paths
                delegate: ListItem {
                    id: vaultItem
                    property string vaultPath: modelData
                    contentHeight: contentColumn.height + 2 * Theme.paddingMedium
                    onClicked: vaultsPage.openVault(vaultPath)

                    Column {
                        id: contentColumn
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            width: parent.width
                            text: vaultsPage.vaultName(vaultItem.vaultPath)
                            color: vaultItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            text: vaultItem.vaultPath === vaultsPage.applicationWindow.openOnLaunchPath
                                    ? "Opens on launch" : vaultItem.vaultPath
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            truncationMode: TruncationMode.Fade
                        }
                    }

                    menu: ContextMenu {
                        MenuItem {
                            visible: vaultsPage.paths.length > 1
                            text: vaultItem.vaultPath === vaultsPage.applicationWindow.openOnLaunchPath
                                    ? "Stop opening on launch" : "Open on launch"
                            onClicked: {
                                if (vaultItem.vaultPath === vaultsPage.applicationWindow.openOnLaunchPath)
                                    vaultsPage.applicationWindow.openOnLaunchPath = ""
                                else
                                    vaultsPage.applicationWindow.openOnLaunchPath = vaultItem.vaultPath
                            }
                        }
                        MenuItem {
                            text: "Remove"
                            onClicked: {
                                var page = vaultsPage
                                var path = vaultItem.vaultPath
                                remorseAction("Removing vault", function() {
                                    var next = []
                                    for (var i = 0; i < page.paths.length; i++)
                                        if (page.paths[i] !== path) next.push(page.paths[i])
                                    page.paths = next
                                    page.savePaths()
                                    if (page.applicationWindow.vaultPath === path)
                                        page.applicationWindow.vaultPath = ""
                                    if (page.applicationWindow.openOnLaunchPath === path)
                                        page.applicationWindow.openOnLaunchPath = ""
                                })
                            }
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: vaultsPage.statusText
                visible: text.length > 0
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }
        }
        VerticalScrollDecorator {}
    }

    Component {
        id: addVaultPicker
        FolderPickerDialog {
            title: "Choose vault folder"
            onAccepted: vaultsPage.addVault(selectedPath)
        }
    }

    Component {
        id: firstVaultPicker
        FolderPickerDialog {
            title: "Choose vault folder"
            acceptDestination: vaultsPage.vaultBrowserPageComponent
            acceptDestinationProperties: ({
                applicationWindow: vaultsPage.applicationWindow,
                vaultBrowserPageComponent: vaultsPage.vaultBrowserPageComponent
            })
            acceptDestinationAction: PageStackAction.Replace
            acceptDestinationReplaceTarget: vaultsPage

            onAccepted: {
                if (!vaultsPage.addVault(selectedPath)) {
                    acceptDestination = vaultsPage
                    acceptDestinationAction = PageStackAction.Pop
                }
            }
        }
    }
}
