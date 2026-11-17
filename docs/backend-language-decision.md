# Backend language decision

## Decision

Use C++ for the initial Sailfish file backend. Keep the application UI in QML and HTML. Start with listing and reading Markdown files from `~/Documents/Obsidian/`; add writes only after device access is confirmed.

## Why Rust was considered

Rust can access files and is proven in a Sailfish application. Whisperfish combines a Rust backend with QML using `qmetaobject-rs`, which exposes Qt objects to QML. Rust remains a viable later direction if the project grows or the owner wants to invest in its toolchain.

## Why C++ for this milestone

The backend needed now is small: list Markdown paths and read a note. C++ connects directly to Qt and QML, and fits the Sailfish SDK's standard app template. Whisperfish's build guide describes additional Rust setup: its documented build requires the SDK Docker engine, and it uses a separately installed Rust toolchain because the SDK-provided one can be too old. That setup is more effort than this initial file-access check needs.

This is a milestone decision, not a rejection of Rust. Revisit it if the backend becomes substantial or Rust becomes a learning goal for the project.

## References

- [Whisperfish source and README](https://github.com/whisperfish/whisperfish)
- [Whisperfish build instructions](https://github.com/whisperfish/whisperfish/blob/main/doc/building-from-source.md)
- [qmetaobject-rs](https://github.com/woboq/qmetaobject-rs)
