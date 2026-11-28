---
name: sailfish-picker-navigation
description: Use when a Sailfish FolderPickerDialog or other picker acceptance must change QML page-stack navigation, including pushing a page after selection or returning to a source page.
---

# Sailfish picker navigation

Choose the page-stack transition based on when the destination page is known. Read the existing flow in the source page first; working create, rename, move, and copy flows are the local reference.

## Destination known before opening the dialog

For a dialog such as the note and folder rename flow, where the destination can be prepared before the user accepts:

1. Push the dialog with `acceptDestination`, `acceptDestinationProperties`, `acceptDestinationAction: PageStackAction.Replace`, and `acceptDestinationReplaceTarget` set to the source page.
2. Prepare the destination page's initial state before acceptance. Sailfish instantiates `acceptDestination` when the dialog opens.
3. In `onAccepted`, perform the operation and refresh or update `acceptDestinationInstance`.
4. If the operation fails, show the error on the source page and change the dialog's `acceptDestination` to the source page with `acceptDestinationAction: PageStackAction.Pop`.

The dialog acceptance replaces pages above the source with the prepared destination. Back from the destination returns to the source; the dialog is not left in the stack.

## Destination known only after selection

For a `FolderPickerDialog` where the destination path is only available as `selectedPath` in `onAccepted`:

1. Leave `acceptDestination` and `acceptDestinationAction` unset.
2. In `onAccepted`, validate and save the selected path. If it requests follow-up navigation, store the destination in a pending property on the source page.
3. Let the picker complete normal acceptance and pop to the source page.
4. On the source page, run a repeating `Timer` while the pending property is set. Wait until both `pageStack.currentPage === sourcePage` and `!pageStack.busy`.
5. Once both conditions hold, copy and clear the pending value, then push the destination page with its initial properties.

Example:

```qml
Page {
    id: sourcePage
    property Component destinationComponent
    property string pendingOpenPath: ""

    function addVault(path) {
        // Validate and persist the selected path first.
        pendingOpenPath = path
    }

    Component {
        id: folderPicker
        FolderPickerDialog {
            onAccepted: sourcePage.addVault(selectedPath)
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: sourcePage.pendingOpenPath.length > 0
        onTriggered: {
            if (pageStack.currentPage !== sourcePage || pageStack.busy) return
            var path = sourcePage.pendingOpenPath
            sourcePage.pendingOpenPath = ""
            pageStack.push(sourcePage.destinationComponent, { selectedPath: path })
        }
    }
}
```

Do not push or replace the destination directly from the picker's `onAccepted`; that runs during dialog acceptance and can leave the picker in Back navigation or overlap pages. A one-shot delay is not reliable because the page-stack transition may still be busy. Poll the stack state until the picker has returned to the source and the transition has ended.

If selection only updates the current page and needs no follow-up page, handle it in `onAccepted` and let the picker pop normally, as the move and copy pickers do.

When an asynchronous callback such as `remorseAction()` needs to access a QML page or delegate, capture the page and item path into local variables before creating the callback. Do not rely on resolving QML IDs later from that callback.
