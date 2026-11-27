# Finding the document a prompt refers to (tag: `docs-lookup`)

Added 2026-11-27 by the owner. Applies to every task in this repository.

## Which document the owner means

1. When a prompt mentions "the document", "the related doc", or a similar reference without naming the file, do not guess
   by searching `docs/`. Look in memory and in the conversation context first.
2. Among the candidates found there, prefer the file that appears most often and most recently.
3. If memory and context still do not identify the document, create a new document for the task instead of searching
   for an existing one. Name it after the task and put it where the documentation rules of this repository say.

## Reading documents under `docs/`

1. Never traverse `docs/` reading the contents of every file, and never grep through all documents to find the one meant.
   Listing file names is allowed.
2. Never read a document under `docs/` in full without authorization. Read a document in full only when the owner
   explicitly names that document and asks for a full read, or grants permission when asked.
3. Without that authorization, ask the owner before reading a document's full text.
4. Exception: a file that these instructions already require to be read in full (for example a tag file marked
   "read in full", or the `git` tag file before a git operation) counts as authorized.
