# Portlight

<p align="center">
  <img src="Harbour-portlight/assets/portlight.svg" alt="Portlight app icon" width="160">
</p>

<p align="center"><strong>A native SailfishOS companion for your Obsidian vault.</strong></p>

> **Unofficial:** Portlight is an independent project and is not affiliated with, endorsed by, or associated with Obsidian or its developers.

Portlight is a lightweight, native SailfishOS app for viewing, editing, and searching an existing Obsidian vault on a Sailfish phone. The first goal is deliberately modest: make ordinary Markdown notes useful on-device while keeping the vault's Markdown files and attachments as the shared source of truth.

Obsidian remains the main desktop and LLM workflow. This project aims for compatibility with the vault's files and common Markdown conventions, not compatibility with Obsidian's application runtime or its plugins.

## Initial user goal

The first usable version should let the user:

- Choose an existing, locally synced vault folder.
- Browse and open Markdown notes.
- Read and edit note contents, then save them reliably.
- Search note text across the vault.

This is the initial milestone, not a promise that every Obsidian feature will be supported. Keep launch time, memory use, and mobile text editing practical on the target phone.

## Applications and approaches considered

- **Obsidian Desktop:** It is built with Electron, but Obsidian is proprietary. Its app source and runtime are not available for a Sailfish port, and a generic WebView cannot host the official app. Community plugins therefore will not run automatically.
- **SilverBullet and HedgeDoc:** Useful web-app references, but a local server or network service is not the target architecture for this phone app.
- **A focused native Sailfish client:** The selected direction is a Sailfish Silica/QML shell with an embedded Gecko WebView for a bundled editor interface, plus a small native Qt/C++ layer for safe access to the chosen vault. The frontend should work offline.

The choice keeps the phone experience native while reusing the ordinary Markdown files that Obsidian and other editors can read. The WebView is an implementation component, not a way to run Obsidian itself.

## Compatibility boundaries

The intended compatibility boundary is the **vault and file format**. Markdown notes and attachments remain canonical. An app-specific database must not become the source of truth; any search index or cache should be rebuildable from the files.

After the basic edit-and-search path works, compatibility can grow around common vault conventions: YAML frontmatter, `[[wiki links]]` and aliases, tags, relative links, images and attachments, callouts, preview, and backlinks. Preserve unfamiliar source syntax when editing where possible.

The initial scope excludes Obsidian's proprietary app/runtime, automatic community-plugin support, full graph view, Dataview semantics, and exact parity with every theme or plugin. Read `.obsidian` settings selectively only when needed; do not modify them without an explicitly supported feature.

## Technical direction

1. **Silica / QML shell:** vault selection, native navigation, menus, settings, file picker, lifecycle, and back-button behavior.
2. **Editing UI:** the optional bundled Gecko WebView in [NotePage.qml](Harbour-portlight/qml/pages/NotePage.qml) hosts the plain-text Markdown editor ([index.html](Harbour-portlight/qml/editor/index.html)); it is not a Markdown preview or an Obsidian runtime. Edits are relayed with Sailfish WebView frame-script async messages ([API reference](https://github.com/sailfishos/sailfish-components-webview/blob/e307cc1683cb55242efadbd8859b93aef96e1f8f/doc/sailfish-webview-webviewadditional.qdoc)). Keep vault access, navigation, and app controls native, and Markdown as the source of truth; visual rendering/editing is deferred.
3. **Native vault access:** narrow, validated operations list, search, read, and atomically write Markdown notes within the current vault. Do not expose unrestricted filesystem access to page JavaScript.
4. **Reliable saves:** save atomically, preserve Unicode and note contents, and add external-change detection before considering the workflow complete.

## Logging

The app uses Qt logging categories: `portlight.app`, `portlight.vault`, and `portlight.storage`. QML diagnostics use the Qt `console` API (`qml` category) and include the originating page in each message. By default, release builds log critical messages only; debug builds log info and more severe messages. Configure categories and message levels before launching the app with `QT_LOGGING_RULES` to override those defaults, for example:

```sh
export QT_LOGGING_RULES='portlight.*.debug=true;qml.debug=true'
```

Rules can be narrowed to one category (for example, `portlight.storage.debug=true`) or set for individual levels (`.debug`, `.info`, `.warning`, `.critical`). The environment must be set in the app launcher's environment; changes take effect after restarting the app. A `QT_LOGGING_CONF` file also takes precedence over the built-in defaults. Logs intentionally omit note contents, search terms, and file paths.

## Roadmap

### 1. Prove the device stack

On the target Xperia 10 II and SailfishOS release, verify the bundled text editor's Gecko compatibility, startup and memory cost, soft keyboard, cursor/selection, Silica pulley menu, page-stack back navigation, and exact Markdown saves. Defer visual Markdown rendering/editing until this baseline works.

### 2. Read and write a chosen vault

Add folder selection and the required permissions. List and read Markdown files, then write through the native layer. Check Unicode, large notes, attachments, atomic saves, and how the sync client behaves when a file changes elsewhere.

### 3. Deliver the first useful workflow

Provide note browsing, viewing, editing, saving, and vault-wide text search. Include dirty-state handling and a clear response to external file changes. The milestone is complete when a note can be selected, edited, saved on-device, and reopened with its changes intact on the Xperia 10 II.

### 4. Add common Obsidian conventions

Use copies of representative vault notes to guide wiki-link resolution, frontmatter preservation, tags, callouts, attachment handling, preview, and basic backlinks/navigation. Preserve source text for unsupported syntax.

### 5. Polish, package, and consider LLM actions

Improve mobile editing and performance, document supported SailfishOS versions and compatibility limits, and verify packaging and WebView dependencies. Consider LLM integration only after core editing is stable and the actual desktop/plugin workflow is understood. Any future integration should be provider-neutral and make connectivity, credentials, privacy, and which vault context is sent explicit.

## Risks to resolve early

- The phone's Gecko may lack APIs required by a modern editor such as CodeMirror 6.
- WebView-to-native calls need strict validation, asynchronous behavior, and vault path confinement.
- Sync clients can change a note while it is open; saves must not silently destroy the other copy.
- Obsidian syntax and plugin-generated content vary; testing on copied real notes is important, and unknown syntax should remain intact.
- Long notes, large vault scans, soft keyboards, and app suspension can cause lag or data loss.
- SailfishOS version, SDK/API level, WebView package, permissions, and distribution requirements need device-specific verification.

## Current project status

The app has been confirmed on-device to access `~/Documents/Obsidian/`, find 363 notes, save edits that sync back to the PC, and search note contents and paths. The current source uses a Silica page stack for folder-by-folder browsing while keeping search vault-wide. Note and folder creation plus note copy, template, move, and confirmed delete actions are implemented in source; verify them on the phone. Folder selection and external-change detection remain to be implemented.

The language choice and Rust alternative are recorded in [the backend decision note](docs/backend-language-decision.md).

## Reference

This direction is based on the supplied `sailfish-obsidian-compatible-editor-handoff.md` implementation handoff. Its conclusions are used here as project context; they are not additional instructions to perform implementation or external actions.
