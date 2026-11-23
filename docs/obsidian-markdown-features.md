# Obsidian Markdown features

This is a syntax-only inventory of Markdown features supported by Obsidian. It covers standard Markdown and Obsidian extensions, not plugins or app features such as backlinks, graph view, or search.

## Standard Markdown

1. Paragraphs and line breaks.
2. Headings: `#` through `######`.
3. Emphasis: *italic*, **bold**, and ***bold italic***.
4. Strikethrough: `~~text~~`.
5. Unordered, ordered, nested, and mixed lists.
6. Task lists: `- [ ]` and `- [x]`.
7. Blockquotes, including nested blockquotes.
8. Horizontal rules: `---`, `***`, or `___`.
9. Inline code and fenced code blocks, optionally with a language.
10. Inline links, reference links, and images.
11. Tables with optional column alignment.
12. Escaped Markdown characters and raw HTML.

## Obsidian formatting extensions

1. Highlight: `==highlighted text==`.
2. Comments, hidden in rendered view: `%%comment%%` (including multiline comments).
3. Footnotes: `[^note]` with `[^note]: definition`; inline footnotes: `^[footnote text]`.
4. Callouts, written as blockquotes:

  ```markdown
  > [!note] Optional title
  > Callout content
  ```

   Callouts can be folded (`[!note]+` or `[!note]-`), nested, and contain Markdown. Obsidian provides built-in callout types and aliases.
5. Math using LaTeX delimiters: inline `$...$` and block `$$...$$`.
6. Mermaid diagrams in fenced `mermaid` code blocks.

## Links and embeds

1. Wiki links: `[[Note]]`, with aliases (`[[Note|Display text]]`), folders, and `.md` extensions.
2. Heading links: `[[Note#Heading]]` and `[[#Heading]]`.
3. Block references: `[[Note#^block-id]]`; define a block ID by ending a paragraph with `^block-id`.
4. Heading and block search links: `[[##search]]` and `[[^^search]]`.
5. Embeds use `!` before a link: `![[Note]]`, `![[Note#Heading]]`, or `![[Note#^block-id]]`.
6. Image embeds can specify dimensions, for example `![[image.png|300x200]]`.
7. Markdown links can also point to notes and files.
8. Embedded files can include supported images, audio, video, and PDFs. PDF embeds support page and height options, for example `![[document.pdf#page=3&height=400]]`.

## Tags and properties

1. Inline tags: `#tag` and nested tags such as `#project/notes`.
2. YAML frontmatter between `---` lines, including `tags`, `aliases`, and `cssclasses`.
3. Properties support text, lists, numbers, checkboxes, dates, date-times, and tags.

## Official references

1. [Basic formatting syntax](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Editing%20and%20formatting/Basic%20formatting%20syntax.md)
2. [Advanced formatting syntax](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Editing%20and%20formatting/Advanced%20formatting%20syntax.md)
3. [Internal links](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Linking%20notes%20and%20files/Internal%20links.md)
4. [Embed files](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Linking%20notes%20and%20files/Embed%20files.md)
5. [Properties](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Editing%20and%20formatting/Properties.md)
6. [Tags](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Editing%20and%20formatting/Tags.md)
7. [Callouts](https://publish-01.obsidian.md/access/f786db9fac45774fa4f0d8112e232d67/Editing%20and%20formatting/Callouts.md)
