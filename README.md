Konstrukt Website
=================

Just stuff that is used for the web representation of [Konstrukt](https://github.com/henry4k/konstrukt).


Runtime dependencies
--------------------

- Lua 5.1+
- Lua packages:
  - LuaFileSystem
  - CMark
  - Lustache


Development dependencies
------------------------

- prove (usually provided by Perl)
- Lua packages:
  - LuaCov
  - LuaCov-Console
  - LuaCheck
  - Lua-TestMore


Layout
------

- source tree:
  Directory which contains documentation in form of markdown files.
- result tree:
  HTML files and other resources are written into this directory.
  The directory layout resembles that of the source tree.
- document:
  A HTML file, which was generated from some file in the source tree.
- fragment:
  A document part, which can be referenced from other documents.
  Fragments are generated from markdown headings and therefore form a tree.
- reference:
  A relative HTTP link to a document or a fragment within a document.
- document index:
  A HTML file, which gives an overview of all documents.
