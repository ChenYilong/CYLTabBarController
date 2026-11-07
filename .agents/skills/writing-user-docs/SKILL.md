---
name: writing-user-docs
description: House style for user-facing documentation — voice, scope, structure, and what to leave out. Use this skill whenever writing, editing, or reviewing anything a user reads to learn how to use a tool — help center articles, getting-started guides, tutorials, feature docs, README usage sections, in-app help, release notes, or FAQ entries. Trigger it even when the request is phrased plainly — "document this feature", "write docs for X", "explain this to users", "write a README for this library", "turn these notes into a guide" — and even when no style guidelines are mentioned. Also use it to review existing docs for tone, bloat, or leaked implementation detail. Do not use it for internal engineering docs, architecture write-ups, RFCs, or code comments.
---

# User-facing documentation

Write for the person using the tool, not the person who built it.

"User" means whoever uses the thing. For an app, that's an end user. For a library, it's the developer who installs it. Either way they are *not* implementing it, and the docs should reflect that.

## Voice

Everyday English — the way you'd explain it to a colleague sitting next to you. Formality doesn't add authority, it just adds distance and words.

- **Second person, active, present tense.** "You tap Save," not "the Save button should be tapped" or "the user will then be able to save."
- **Cut "just," "simply," "easy," "obviously."** They add nothing when things work, and read as mockery when they don't.
- **No marketing adjectives.** "Powerful," "seamless," "robust," "intuitive" — that's the author admiring the product. The reader is mid-task and doesn't care.
- **One term per concept, matching the UI exactly.** If the button says *Workspace*, the docs never say "project" or "team space." Varying your vocabulary is good prose and bad documentation — every synonym reads as a new concept.

## Scope: what goes in

Include only what the reader needs to use the tool. The default is to leave things out.

**Implementation details stay out.** Not the database, the queue, the framework, the algorithm's name, the internal service, the refactor it took to ship. The test isn't "is this technical?" — it's **"will the reader be surprised, or make a wrong decision, without it?"**

Observable behavior passes that test even when it sounds technical, and belongs in the docs: rate limits, offline behavior, what syncs and when, where files are stored, what happens on a conflict, what survives a reinstall. The machinery producing that behavior doesn't.

**Concise means no filler, not short.** Every sentence earns its place. A thorough troubleshooting section is still concise if none of it is padding — and a two-line page is bloated if one line is a welcome message. Cut preambles, restatements of the heading, and "in this article you will learn."

## Structure

- **Organize by user goal, not by feature or screen.** Headings are things people want to do — "Share a report with someone outside your team" — not nouns like "Sharing module."
- **Lead with the outcome, then the steps.** People need to know they're on the right page before investing in step 1.
- **Prerequisites and limits go up front.** Required plan, permission, platform, file size cap. Discovering the blocker at step 6 is the worst possible moment.
- **One page answers one question, and stands alone.** Most readers arrive from search or a deep link, never from page 1. Assume no one read the previous page; link instead of assuming.
- **Pick one path.** Where three ways exist, document the recommended one. Alternatives get a short note at the end, or nothing.

## Cover the unhappy path

This is the most-skipped section and the one people actually search for.

- **Document the failure cases**: what the error says, what causes it, what to do next.
- **Say what the feature doesn't do** when users predictably assume it does. Cheaper than a support ticket.
- **Warn before destructive actions, never after.** The warning goes above the step it applies to.

## Keep it from rotting

- **Real examples with real-looking data.** No `foo`, no `test123`, no lorem ipsum. Examples should be copy-pasteable and produce the result shown.
- **No time-relative language.** "New," "recently," "currently," "coming soon" — all rot silently. So do roadmap promises.
- **Walk every procedure literally.** If someone following it word-for-word can't finish, the doc is wrong — not the reader.

## Before publishing

Read the draft once looking only for these:

1. Anything the reader doesn't need to finish the task → cut it.
2. Anything about how it works internally → cut it, unless behavior depends on it.
3. Any sentence you wouldn't say out loud → rewrite it.
4. What happens when this goes wrong → is that answered?
