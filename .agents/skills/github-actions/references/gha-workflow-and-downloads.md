---
title: Workflow Wiring and Artifact Downloads
impact: CRITICAL
tags: github-actions, workflow, artifacts, gh-cli, rest-api, simulator, emulator
---

# Skill: Workflow Wiring and Artifact Downloads

Use this workflow to run iOS simulator and Android emulator builds in cloud CI and expose artifact metadata for scripted retrieval.

## Minimum Required Inputs

Set these before first run:
- iOS scheme: exact Xcode scheme name (for example `YourApp`).
- Android variant: Gradle variant for emulator artifacts (usually `Debug`).
- Branch strategy: branches for `push` and `pull_request` triggers (default below uses `main`).
- Retention days: artifact retention period passed to upload steps (for example `7`).

## Repo-Compat Checklist (Before First Run)

- Confirm the iOS scheme exists and builds locally.
- Confirm `pod install` works in CI context from iOS source dir.
- Confirm `android/gradlew` is executable (`chmod +x android/gradlew` if needed).
- Confirm `npx react-native config` resolves valid `project.ios.sourceDir` and `project.android.sourceDir`.

## Quick Config

1. Create `.github/workflows/mobile-build.yml`.
2. Call local composite actions from this skill (`github-actions/ios-build`, `github-actions/android-build`).
3. Keep `actions/upload-artifact@v4` output IDs.
4. Retrieve with `gh run download` or `gh api`.

## When to Use

- Need one pipeline for simulator/emulator artifacts.
- Need PR, push, and manual dispatch triggers.
- Need deterministic artifact retrieval in CI/CD or external tooling.

## Workflow Template (`.github/workflows/mobile-build.yml`)

```yaml
name: RN Cloud Build

on:
  # Baseline trigger strategy: validate incoming changes and direct branch updates.
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      ios_scheme:
        description: iOS scheme name
        required: true
        default: YourApp
        type: string
      ios_configuration:
        description: iOS configuration
        required: true
        default: Debug
        type: string
      android_variant:
        description: Android Gradle variant
        required: true
        default: Debug
        type: string
      artifact_retention_days:
        description: Artifact retention days
        required: true
        default: '7'
        type: string

permissions:
  contents: read
  actions: read

env:
  IOS_SCHEME: YourApp
  IOS_CONFIGURATION: Debug
  ANDROID_VARIANT: Debug
  ARTIFACT_RETENTION_DAYS: '7'

jobs:
  ios:
    name: iOS simulator build
    runs-on: macos-latest
    outputs:
      artifact_name: ${{ steps.build.outputs.artifact-name }}
      artifact_id: ${{ steps.build.outputs.artifact-id }}
      artifact_url: ${{ steps.build.outputs.artifact-url }}
    steps:
      - uses: actions/checkout@v4

      - name: Resolve Node version from package.json engines
        id: node-version
        run: |
          set -euo pipefail
          NODE_SPEC="$(python3 - <<'PY'
import json
from pathlib import Path
pkg = Path('package.json')
if not pkg.exists():
    print('22')
else:
    data = json.loads(pkg.read_text())
    print((data.get('engines', {}).get('node') or '22').strip())
PY
          )"
          echo "value=$NODE_SPEC" >> "$GITHUB_OUTPUT"

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ steps.node-version.outputs.value }}
          cache: npm

      - name: Install JS dependencies
        run: npm ci

      - name: Install CocoaPods dependencies
        run: |
          set -euo pipefail
          IOS_SOURCE_DIR="$(npx react-native config | node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(j.project?.ios?.sourceDir || 'ios')")"
          cd "$IOS_SOURCE_DIR"
          pod install --repo-update

      # Optional: only add ruby/setup-ruby when this repo enforces Ruby tooling
      # (for example via .ruby-version and Bundler workflow).
      # - uses: ruby/setup-ruby@v1
      #   with:
      #     bundler-cache: true

      - name: Resolve iOS inputs
        id: ios-inputs
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "scheme=${{ inputs.ios_scheme }}" >> "$GITHUB_OUTPUT"
            echo "config=${{ inputs.ios_configuration }}" >> "$GITHUB_OUTPUT"
            echo "retention=${{ inputs.artifact_retention_days }}" >> "$GITHUB_OUTPUT"
          else
            echo "scheme=${{ env.IOS_SCHEME }}" >> "$GITHUB_OUTPUT"
            echo "config=${{ env.IOS_CONFIGURATION }}" >> "$GITHUB_OUTPUT"
            echo "retention=${{ env.ARTIFACT_RETENTION_DAYS }}" >> "$GITHUB_OUTPUT"
          fi

      - name: Build iOS simulator
        id: build
        uses: ./.github/actions/github-actions/ios-build
        with:
          scheme: ${{ steps.ios-inputs.outputs.scheme }}
          configuration: ${{ steps.ios-inputs.outputs.config }}
          artifact-prefix: rn-ios-simulator
          artifact-retention-days: ${{ steps.ios-inputs.outputs.retention }}

  android:
    name: Android emulator build
    runs-on: ubuntu-latest
    outputs:
      artifact_name: ${{ steps.build.outputs.artifact-name }}
      artifact_id: ${{ steps.build.outputs.artifact-id }}
      artifact_url: ${{ steps.build.outputs.artifact-url }}
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - name: Resolve Node version from package.json engines
        id: node-version
        run: |
          set -euo pipefail
          NODE_SPEC="$(python3 - <<'PY'
import json
from pathlib import Path
pkg = Path('package.json')
if not pkg.exists():
    print('22')
else:
    data = json.loads(pkg.read_text())
    print((data.get('engines', {}).get('node') or '22').strip())
PY
          )"
          echo "value=$NODE_SPEC" >> "$GITHUB_OUTPUT"

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ steps.node-version.outputs.value }}
          cache: npm

      - name: Install JS dependencies
        run: npm ci

      - name: Resolve Android inputs
        id: android-inputs
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "variant=${{ inputs.android_variant }}" >> "$GITHUB_OUTPUT"
            echo "retention=${{ inputs.artifact_retention_days }}" >> "$GITHUB_OUTPUT"
          else
            echo "variant=${{ env.ANDROID_VARIANT }}" >> "$GITHUB_OUTPUT"
            echo "retention=${{ env.ARTIFACT_RETENTION_DAYS }}" >> "$GITHUB_OUTPUT"
          fi

      - name: Build Android emulator APK
        id: build
        uses: ./.github/actions/github-actions/android-build
        with:
          variant: ${{ steps.android-inputs.outputs.variant }}
          artifact-prefix: rn-android-emulator
          artifact-retention-days: ${{ steps.android-inputs.outputs.retention }}

  summary:
    name: Build summary
    runs-on: ubuntu-latest
    needs: [ios, android]
    steps:
      - name: Publish artifact metadata
        run: |
          {
            echo "## RN Cloud Build Artifacts"
            echo ""
            echo "- iOS simulator (.app.tar.gz): name=${{ needs.ios.outputs.artifact_name }}, id=${{ needs.ios.outputs.artifact_id }}"
            echo "- Android emulator (.apk): name=${{ needs.android.outputs.artifact_name }}, id=${{ needs.android.outputs.artifact_id }}"
            echo ""
            echo "Artifact URLs (auth required):"
            echo "- iOS: ${{ needs.ios.outputs.artifact_url }}"
            echo "- Android: ${{ needs.android.outputs.artifact_url }}"
          } >> "$GITHUB_STEP_SUMMARY"
```

## CocoaPods and Ruby Notes

- Run `pod install` from `ios/` or from `project.ios.sourceDir` resolved via `npx react-native config`.
- Do not assume Bundler or pinned Ruby is always required.
- `ruby/setup-ruby` is optional and should be added only when repo policy enforces Ruby tooling (for example `.ruby-version` and Bundler-managed pods).

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `ruby/setup-ruby` or Bundler fails | Repo does not require Ruby toolchain in CI | Remove Ruby setup and run plain `pod install` |
| `xcodebuild: Scheme ... not found` | Wrong iOS scheme value | Use exact shared scheme from Xcode project/workspace |
| `Task ':app:assembledebug' not found` | Wrong Android variant casing | Use Gradle-style casing (`Debug`, `Release`, `StagingDebug`) |
| `pod install --repo-update` is slow or flaky | CocoaPods spec repo updates | Retry, cache Pods, or drop `--repo-update` when lockfile + mirror are stable |

## Download Artifacts with `gh`

```bash
# 1) Find recent runs for this workflow
gh run list --workflow "RN Cloud Build" --limit 10

# 2) Download by run id + artifact name
gh run download <run-id> -n <artifact-name> -D ./artifacts

# 3) Inspect artifacts for a run (IDs + names)
gh api repos/<owner>/<repo>/actions/runs/<run-id>/artifacts \
  --jq '.artifacts[] | {id, name, size_in_bytes, expired}'
```

## Download Artifacts with Direct REST API

```bash
# List repo artifacts
curl -sS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/<owner>/<repo>/actions/artifacts" | jq '.artifacts[] | {id, name}'

# Download one artifact zip by ID
curl -L \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/<owner>/<repo>/actions/artifacts/<artifact-id>/zip" \
  -o artifact.zip
```

## Common Pitfalls

- Forgetting to set `permissions.actions: read` for API-driven artifact listing.
- Assuming artifact URLs are public; they require authenticated access.
- Not pinning artifact names, making `gh run download -n` brittle.

## Related Skills

- [gha-ios-composite-action.md](gha-ios-composite-action.md)
- [gha-android-composite-action.md](gha-android-composite-action.md)
