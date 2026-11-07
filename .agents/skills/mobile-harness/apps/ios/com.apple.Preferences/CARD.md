# iOS Settings Card

Bundle id: `com.apple.Preferences`

Use this card only when iOS Settings is the foreground app or the task explicitly targets device settings.

## Useful Labels

- On iOS 26 the root Settings search field (placeholder `Search`) is in the
  bottom toolbar.
- The root list also has a `Search` row (search settings pane) with the same
  label.
- Back navigation labels vary by current pane.
- Permission and privacy panes can require precise labels.

## Flow Notes

- Prefer Settings search for deep destinations when visible.
- Confirm the exact page title after navigation.
- Use one Back action at a time and observe after each press.

## Traps

- Some settings changes are destructive, privacy-sensitive, or require passcode confirmation. Ask before reset, account removal, VPN, profiles, accessibility, or permission changes unless the user explicitly requested that exact action.
- If Settings asks for passcode, Apple ID, password, biometric confirmation, payment, or recovery, stop and read `core/credentials/GUIDE.md`.
