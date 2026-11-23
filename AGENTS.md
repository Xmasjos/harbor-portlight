# Repository instructions

- Question assumptions, verify claims, and prefer the smallest correct change and concise explanations.
- For Portlight-specific terminology, read [GLOSSARY.md](GLOSSARY.md) when a task involves those concepts.
- When lasting concepts, architecture, or workflows change, update relevant harness docs (glossary, instructions, skills) if useful; skip implementation details.
- Do not run project builds unless the user explicitly asks; build outputs are not used in this workflow.
- For Sailfish APIs, consult the [Sailfish app docs](https://docs.sailfishos.org/Develop/Apps/) and [Silica API docs](https://sailfishos.org/develop/docs/silica).
- Use Qt docs matching the active Sailfish SDK: check `qmake -query QT_VERSION` there, not host Qt. QML import versions are module API versions; check project imports and RPM dependencies, and verify device/runtime Qt when behavior depends on it.
