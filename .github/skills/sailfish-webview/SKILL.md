---
name: sailfish-webview
description: Build and debug Sailfish OS Gecko WebView integrations.
---

# Sailfish OS WebView

Use this skill when building, debugging, or packaging Sailfish OS QML WebView content, especially communication between bundled HTML/JavaScript and QML.

## Project architecture

- The native Silica/QML UI owns navigation, vault access, validation, and saving. Web content must not receive unrestricted filesystem or backend access.
- In this app, `Harbour-portlight/qml/pages/NotePage.qml` optionally loads the local, text-only editor in `Harbour-portlight/qml/editor.html`.
- QML updates the editor with `runJavaScript`. Editor input reaches QML through `Harbour-portlight/qml/editor-frame.js`, `loadFrameScript`, `addMessageListener`, and `onRecvAsyncMessage`.

## Procedure

1. Inspect the active QML imports, target SDK, and device OS version. Follow the Sailfish WebView API available in that environment; do not assume Qt WebEngine, Qt WebView, or browser APIs are interchangeable.
2. Keep the WebView boundary narrow. Use `runJavaScript` for QML-to-page updates. For page-to-QML events, load a frame script before page content and register a named async-message listener; the frame script can observe DOM events and call `sendAsyncMessage(name, data)`.
3. Validate every received message in QML: match the expected name and check the shape and types of its data before changing application state.
4. Resolve bundled assets relative to the QML file with `Qt.resolvedUrl`. Add new QML assets to `Harbour-portlight/Harbour-portlight.pro` under `DISTFILES`.
5. Verify the exact round trip on the target runtime: initialize the page, update text from QML, edit text in the page, and confirm the expected QML state changes. Build and install with the project's configured Sailfish SDK target.

## Pitfalls

- In this repo's current WebView stack, page-side `navigator.qt` is undefined and `experimental` is not a supported QML property. Use the frame-script async-message API instead.
- `runJavaScript` executes asynchronously and requires an explicit `return`; consume returned values with its callback rather than assuming a synchronous result.
- Keep HTML and frame scripts local and bundled. Do not disable browser security settings or expose vault operations to page JavaScript to work around a bridge issue.
- A successful desktop/static check does not prove device behavior; test against the actual Sailfish OS runtime as well as the SDK target.

## Reference

- [Sailfish WebView async messages and frame scripts](https://github.com/sailfishos/sailfish-components-webview/blob/e307cc1683cb55242efadbd8859b93aef96e1f8f/doc/sailfish-webview-webviewadditional.qdoc)
- [Project WebView design](../../../README.md#technical-direction)
