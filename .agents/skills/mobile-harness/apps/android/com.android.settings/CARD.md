# Android Settings Card

Package: `com.android.settings`

Use this card only when Android Settings is the foreground package or the task explicitly targets device settings.

## Useful Labels

- Search Settings: `Search settings`.
- Apps list: `Apps`.
- Accessibility: `Accessibility`.
- Keyboard settings: labels vary by Android version.

## Flow Notes

- Prefer Settings search for deep destinations.
- Confirm the exact page title after navigating.
- Use Back once at a time and observe after each press.

## Traps

- Some settings changes are destructive or privacy-sensitive. Ask before reset, uninstall, clear data, account removal, VPN, accessibility, or permission changes unless the user explicitly requested that exact action.
- If Settings asks for PIN/password/biometric confirmation, stop and read `core/credentials/GUIDE.md`.
