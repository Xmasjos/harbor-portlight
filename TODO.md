# TODO

Current device workflow: search the configured vault, open a Markdown note, edit it, and save it back to the synced file.

## 1. Make vault navigation user-friendly (Silica page stack; verified on device)

- The native Sailfish QML browser lists folders and Markdown notes in the current folder; tapping a folder pushes another Silica page, and standard page-stack back navigation goes up.
- Search remains vault-wide and results show their relative paths.
- Folder and file navigation stays in QML/Silica; the WebView remains optional for editing or preview.
- `.obsidian` internals are excluded from browsing and search unless a supported feature needs them.

### 1.a Note actions (implemented & verified on device)

- Add **Create new note** to the notes browsing page's pulley menu.
- Add **Create folder** to the notes browsing page's pulley menu.
- Add a note & folder item context menu with **Delete** (remorse timer), **Copy**, **rename** and **Move**.

### 1.b Notes list polish (implemented & verified on device)

- Add type-specific Sailfish icons in `NotesPage`: `icon-m-file-folder` for non-empty folders, `icon-m-folder` for empty folders, `icon-m-file-note` for Markdown, `icon-m-file-document` for `.txt`, `icon-m-file-image` for common image formats, `icon-m-file-pdf` for PDFs, `icon-m-file-formatted` for word-processing documents, `icon-m-file-presentation` for presentations, and the matching archive/audio/video/spreadsheet icons where applicable. Use `icon-m-file-other` as the fallback. Remove the trailing `/` from folder names once the folder icon is present.
- Have the vault listing classify readable files by extension and report whether each folder contains any visible items, so empty and non-empty folder icons can differ. Keep file opening behavior explicit: Markdown and text open in the editor; other formats can be shown in the list and handed to the system or an appropriate viewer when supported.
- Add a pulldown toggle for unsupported files, hidden by default: show **Show unsupported files** while hidden and **Hide unsupported files** while shown. Persist the preference if appropriate, and keep folder empty/non-empty status based on its contents even while unsupported files are hidden.
- Replace free-form destination paths for **Move** and **Copy** with a native folder picker rooted at the current vault. After choosing a destination folder, let the user confirm or edit the item's name; show the resulting destination path before applying the action.
- Keep **Create note** and **Create folder** anchored to the current folder, with a name field as the primary input. Do not open the folder picker by default: users are already browsing the target location. If creation needs a different location, offer an explicit “Choose location” action that uses the same vault-scoped picker.
- Keep picker destinations relative to the vault and prevent moving a folder into itself or one of its descendants. Refresh the visible folder after a successful action and navigate to the new location only when appropriate.

## 2. Protect notes changed elsewhere (implemented & verified on device)

- Detect when a note changes on another device while it is open.
- Before saving over a changed file, offer a safe choice such as reload or save the current text as a separate copy.
- Never silently overwrite the newer synced version.

## 3. Let the user choose the vault in QML (implemented & verified on device)

- Add a native QML folder-selection flow for an existing, locally synced vault.
- Store the chosen folder and use it for browsing, search, reading, and saving instead of assuming `~/Documents/Obsidian/`.
- Confirm SailfishOS permissions and access to the selected folder on-device.

## 4. Improve Markdown editing

### 4.1 Separate the source and WebView editors (implemented & verified on device)

- Move the source editor and WebView editor into separate QML components with a shared title/text interface.
- Keep note state, vault access, navigation, renaming, saving, and external-change handling native in `NotePage`.

### 4.2 Include the note filename in the HTML editor (implemented & verified on device)

- Show and edit the filename in the WebView editor; keep the native title field when using the source editor.
- Send title changes to QML through validated WebView messages and let QML perform the file rename.

### 4.3 Integrate a richer WebView editor

- Replace the HTML editor's `<textarea>` with bundled CodeMirror 6 if it works reliably in the target SailfishOS Gecko WebView; prefer it over Monaco for this app.
- Preserve the original Markdown exactly unless edited, and retain autosave, explicit save, and external-change protection.

### 4.4 Verify the editing workflow on-device

- Test editor initialization and text/title updates in both directions, filename renaming, soft keyboard, cursor and selection, copy/paste, pulley menu, and page-stack back behavior.
- Confirm save and external-change protection still work, including notes with frontmatter and unfamiliar Markdown syntax.

### 4.5 Consider visual Markdown editing

- Only after text editing is reliable, consider rendering/editing inline images, links, checkboxes, and code blocks without losing source syntax.

### 4.6 Add a native NotePreviewEditor

- Keep the pure source editor available as a separate editing mode.
- In preview mode, render inactive blocks and show the Markdown source for the block being edited; allow checkbox and link interaction without preventing direct source edits.
- [ ] Standard Markdown features ([inventory](docs/obsidian-markdown-features.md#standard-markdown)):
  - [x] Feature 1
  - [x] Feature 2
  - [ ] Feature 3
  - [ ] Feature 4
  - [ ] Feature 5
  - [ ] Feature 6
  - [ ] Feature 7
  - [ ] Feature 8
  - [ ] Feature 9
  - [ ] Feature 10
  - [ ] Feature 11
  - [ ] Feature 12
- [ ] Obsidian formatting extensions ([inventory](docs/obsidian-markdown-features.md#obsidian-formatting-extensions)):
  - [ ] Feature 1
  - [ ] Feature 2
  - [ ] Feature 3
  - [ ] Feature 4
  - [ ] Feature 5
  - [ ] Feature 6
- [ ] Links and embeds ([inventory](docs/obsidian-markdown-features.md#links-and-embeds)):
  - [ ] Feature 1
  - [ ] Feature 2
  - [ ] Feature 3
  - [ ] Feature 4
  - [ ] Feature 5
  - [ ] Feature 6
  - [ ] Feature 7
  - [ ] Feature 8
- [ ] Tags and properties ([inventory](docs/obsidian-markdown-features.md#tags-and-properties)):
  - [ ] Feature 1
  - [ ] Feature 2
  - [ ] Feature 3

## 5. Create and organize notes (implemented & verified on device)

- Allow renaming notes with the native QML interface.

## 6. Follow Obsidian-style links

- Recognize `[[note links]]` and aliases such as `[[note|label]]` in reading and preview modes.
- Resolve links by note name and relative path, show an understandable choice when names are ambiguous, and open the result in the app.
- Preserve the original Markdown link text when editing.
- When a note contains a link to a missing note, offer to create and open the linked note.

## 7. Make important notes easy to return to

- Add a recent notes list and a small favorites/bookmarks list for notes and folders.
- Keep these controls reachable from the main QML navigation.
- Store app-specific favorites without changing `.obsidian` until its settings format is deliberately supported.

## 8. Add a useful reading mode

- Let the user switch between Markdown source and rendered reading view.
- Start with headings, lists, links, emphasis, code blocks, and callouts; keep the source available for editing.
- Ensure long notes remain readable and scrolling works well on the phone.

## 9. Add note outline and backlinks

- Show a heading outline for the open note and let the user jump to a heading.
- Show notes that link to the current note, with a short matching excerpt.
- Add unlinked mentions only after linked backlinks work reliably.

## 10. Support common attachments

- Display local images referenced by Markdown and Obsidian embeds.
- Let the user open common attachments from a note; define a clear fallback for unsupported file types.
- Keep attachment paths inside the selected vault.

## 11. Browse tags and properties

- Show tags used in a note and allow browsing/searching notes by tag.
- Preserve YAML frontmatter and provide a simple readable view for common properties.
- Avoid rewriting unknown property values or formatting during ordinary note edits.

## 12. Explore limited Obsidian plugin compatibility (low priority)

- Do not promise that existing Obsidian plugins run in this app. They depend on Obsidian's application and plugin APIs, which this Sailfish client does not provide.
- First identify specific plugin behaviors that matter in the user's vault, then consider implementing those behaviors natively or through a focused compatibility layer.
- Revisit a broader plugin strategy only after browsing, editing, search, and sync-conflict handling are reliable.

## 13. Add a settings page (implemented & verified on device)

- Provide a native settings page reachable from the main navigation.
- Choose the vault folder with the Sailfish folder picker.
- Configure automatic note saving and its delay.

## 14. Make the app cover useful (implemented & verified on device)

- Show the currently open note or folder on the cover.
- Add a cover action to create a note in that current location.
- Keep the displayed location and create-note action in sync with navigation and the active vault.

## 15. Support reusable note templates

- Provide a functional way to save or designate notes as templates and create new notes from them.
- Make template use distinct from copying an existing note, with a clear place to manage templates.

## 16. Add an About page

- Add an About page reachable from the app navigation.
- Include the disclaimer that Portlight is independent and is not affiliated with or endorsed by Obsidian or its developers.
- Start the page with the app name, then the app icon, then the disclaimer, then a short description, then a section for issue reporting with the github repo link

## 17. Capture quick notes (implemented & verified on device)

- Provide a quick capture flow for jotting down text without first browsing to or naming a note. Save quick notes in the configured vault folder, chosen through Settings with a folder picker; make the destination visible and handle a missing or unavailable folder clearly. See also [Daily notes](#18-support-daily-notes) for the related date-based note workflow and shared destination-setting behavior.
- Offer quick-note capture as an optional cover action, alongside the existing action that creates a blank note in the current folder. The quick-note action should open the capture flow and save to its configured destination, regardless of the currently browsed folder.
- On save, create a Markdown note with a predictable timestamp-based name and avoid overwriting an existing note. Let the user enter the text before saving and open the created note afterward for continued editing.
- Keep the initial flow focused on text capture. Consider a home-screen/app shortcut and sharing text into Portlight as follow-up entry points if SailfishOS supports them cleanly; voice capture and attachments can wait until there is a clear need.

## 18. Support daily notes

- Provide a daily-note action that opens today's note, creating it when it does not exist. Configure the destination folder and date-based filename format, and handle missing or unavailable folders clearly.
- Keep daily notes distinct from standalone quick notes: a daily note is one note per date that is reopened and extended throughout the day. See also [Capture quick notes](#17-capture-quick-notes) for the related capture flow, optional cover entry point, and shared vault-folder setting; consider offering an explicit way to append a quick capture to today's note.
- Define behavior for date changes, existing notes, and filename collisions, and open the daily note for continued editing after creation.

## 19. Import from jolla-notes
- Provide a button in the settings page to import all notes from the default sailfish notes app
- The notes should be imported to the 'quick notes' folder
- It might be that this is not possible for a sailjail enabled app. If so, see how filebrowser adds a 'run as root' option

## 20. Investigate memory usage
- Investigate why the app's memory usage is high and identify opportunities to reduce it.

## 21. Reduce processor usage
- When the app is not in the foreground, stop active folder watches so no folder watches remain running in the background.

## Inspiration

- Obsidian [Bookmarks](https://help.obsidian.md/plugins/bookmarks) covers quick access to frequently used files, folders, and searches.
- Obsidian [Backlinks](https://help.obsidian.md/plugins/backlinks) shows linked and unlinked mentions for the active note.
