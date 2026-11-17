# TODO

Current device workflow: search the configured vault, open a Markdown note, edit it, and save it back to the synced file.

## 1. Make vault navigation user-friendly (Silica page stack; verify on device)

- The native Sailfish QML browser lists folders and Markdown notes in the current folder; tapping a folder pushes another Silica page, and standard page-stack back navigation goes up.
- Search remains vault-wide and results show their relative paths.
- Folder and file navigation stays in QML/Silica; the WebView remains optional for editing or preview.
- `.obsidian` internals are excluded from browsing and search unless a supported feature needs them.

### 1.a Note actions (implemented in source; verify on device)

- Add **Create new note** to the notes browsing page's pulley menu.
- Add **Create folder** to the notes browsing page's pulley menu.
- Add a note item context menu with **Delete** (remorse timer), **Copy**, and **Move**.

## 2. Protect notes changed elsewhere

- Detect when a note changes on another device while it is open.
- Before saving over a changed file, offer a safe choice such as reload or save the current text as a separate copy.
- Never silently overwrite the newer synced version.

## 3. Let the user choose the vault in QML

- Add a native QML folder-selection flow for an existing, locally synced vault.
- Store the chosen folder and use it for browsing, search, reading, and saving instead of assuming `~/Documents/Obsidian/`.
- Confirm SailfishOS permissions and access to the selected folder on-device.

## 4. Improve Markdown editing

- The app already lets the user edit and save Markdown note text directly; programming-code edits are not needed for normal note editing.
- Improve the in-app editor for phone use: comfortable cursor and selection behavior, a Markdown preview, and small editing helpers only where they make common tasks easier.
- Preserve the original Markdown source, frontmatter, and unfamiliar syntax when editing or previewing.

## 5. Create and organize notes

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

## 13. Add a settings page

- Provide a native settings page reachable from the main navigation.
- Put app preferences and vault-related options there as they are introduced.

## 14. Make the app cover useful

- Show the currently open note or folder on the cover.
- Add a cover action to create a note in that current location.
- Keep the displayed location and create-note action in sync with navigation and the active vault.

## 15. Support reusable note templates

- Provide a functional way to save or designate notes as templates and create new notes from them.
- Make template use distinct from copying an existing note, with a clear place to manage templates.

## Inspiration

- Obsidian [Bookmarks](https://help.obsidian.md/plugins/bookmarks) covers quick access to frequently used files, folders, and searches.
- Obsidian [Backlinks](https://help.obsidian.md/plugins/backlinks) shows linked and unlinked mentions for the active note.
