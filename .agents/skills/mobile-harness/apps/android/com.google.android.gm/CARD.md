# Gmail Android Card

Package: `com.google.android.gm`

Use this card only when Gmail is the foreground package or the task explicitly targets Gmail.

## Useful Labels

- Compose: often visible as `Compose`.
- Search: often visible as `Search in mail`.
- Navigation drawer: content description may include `Open navigation drawer`.
- Account switcher: profile avatar near the top-right.

## Flow Notes

- Prefer structured state labels over coordinate taps.
- After launching, wait for inbox or account picker before acting.
- If Gmail asks to add an account, sign in, or verify identity, stop and read `core/credentials/GUIDE.md`.

## Traps

- Inbox rows can have repeated text; verify the opened message subject after tapping.
- Search results can lag. Observe again before acting on the first result.
- Do not store email contents in memory unless the user explicitly asks.
