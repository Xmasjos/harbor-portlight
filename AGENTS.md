# Repository instructions

- Question assumptions, verify claims, and prefer the smallest correct change and concise explanations.
- Apply DRY when behavior and responsibility match: search for existing code that does the same job and extend or share it instead of adding a parallel version. Similar code with a different use or reason to change should remain separate so each implementation can diverge as needed.
- For Portlight-specific terminology, read [GLOSSARY.md](GLOSSARY.md) when a task involves those concepts.
- When lasting concepts, architecture, or workflows change, update relevant harness docs (glossary, instructions, skills) if useful; skip implementation details.
- Do not run project builds unless the user explicitly asks; build outputs are not used in this workflow.
- For Sailfish APIs, consult the [Sailfish app docs](https://docs.sailfishos.org/Develop/Apps/) and [Silica API docs](https://sailfishos.org/develop/docs/silica).
- Use Qt docs matching the active Sailfish SDK: 5.6.3
