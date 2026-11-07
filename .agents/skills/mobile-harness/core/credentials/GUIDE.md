---
name: mobile-harness-credentials
description: Use when a mobile screen asks for login, password, API key, OTP, 2FA, recovery code, passcode, payment details, or other secrets while using mobile-harness.
---

# Mobile Credentials

Default behavior: stop and ask the user if the credentials are not set or explicitly authorized.

## Credential Screens

Treat these as credential or human-gated screens:

- username, email, phone login
- password
- API key.
- iOS passcode, Apple ID, or device unlock prompt
- payment card, bank, billing, or purchase confirmation

## Ask Before Acting

Ask one short question and wait. Offer concrete options:

- user takes over on the device
- user provides/authorizes a local credentials file
- user enters credentials.
- user approves skipping the login-gated task

## Local Credential Files

`local/credentials/` means `<state-root>/local/credentials/`, where `<state-root>` is defined in the harness `AGENTS.md`. Resolve it from there, never from the current working directory, which may be tracked by git. If the user explicitly authorizes stored credentials, read only the file for the current app id:

```text
<state-root>/local/credentials/<app-id>.md
```

Example shape:

```markdown
# com.example.app

- username: user@example.com
- password: stored outside chat
- notes: ask user for OTP every login
```

Use only the minimum required field. Redact values in logs and summaries.

## Never

- Write credentials to `local/memory/`.
- Commit credential files.
- Print secrets back to the user.
- Reuse credentials for a different app id.
- Submit payment, purchase, deletion, or account recovery without explicit approval for that exact action.
