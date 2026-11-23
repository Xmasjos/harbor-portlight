# Portlight

Portlight is an unofficial native SailfishOS companion for working with an existing Obsidian vault. It works with the vault's files; it does not run Obsidian or its plugins.

## Vault and notes

**Vault**:
A user's locally available collection of notes and related files; its files are the source of truth.

**Note**:
A Markdown file in a vault.

**Markdown source**:
The plain-text contents of a note, including Markdown and unfamiliar syntax; the source being edited, not a rendered preview.

**Attachment**:
A non-note vault file, such as an image, that a note can link to or embed.

## Capture

**Quick note**:
A timestamp-named Markdown note for jotting down text. Saved in the configured quick-note folder, regardless of the folder being browsed.

## Editing

**WebView**:
The optional embedded Sailfish Gecko component that hosts the bundled CodeMirror editor; it is not an Obsidian runtime or Markdown preview. Vault access and app controls remain native.

**Preview editor**:
A native editing view that renders Markdown blocks and reveals a block's source while it is being edited.
_Avoid_: Preview mode

**External change**:
A change to an open note made outside the app; treated as a save conflict to prevent silently overwriting the newer file.
