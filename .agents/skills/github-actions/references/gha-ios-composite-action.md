---
title: iOS Simulator Composite Action (RN CLI)
impact: HIGH
tags: ios, simulator, github-actions, react-native, xcodebuild, artifact
---

# Skill: iOS Simulator Composite Action (RN CLI)

Composite action template for building React Native iOS simulator apps in GitHub Actions and uploading `.app.tar.gz` artifacts.

## Quick Config

1. Create `.github/actions/github-actions/ios-build/action.yml`.
2. Copy the template below.
3. Set your app `scheme` and optional `configuration`.
4. Use `actions/upload-artifact@v4` outputs (`artifact-id`, `artifact-url`).
5. Download later by ID (REST) or by run/name (`gh run download`).

## When to Use

- Need cloud iOS simulator build artifacts for QA or PR validation.
- Need deterministic artifact naming and machine-readable IDs.
- Need RN CLI project discovery without Rock (`npx react-native config`).

## Prerequisites

- macOS runner (`macos-latest` recommended).
- Xcode scheme is known and buildable in CI.
- JS dependencies installed before invoking the action.

## Template (`.github/actions/github-actions/ios-build/action.yml`)

```yaml
name: React Native iOS Simulator Build
description: Build React Native iOS simulator app in GitHub Actions and upload artifact

inputs:
  working-directory:
    description: Project root
    required: false
    default: "."
  scheme:
    description: Xcode scheme
    required: true
  configuration:
    description: Xcode configuration
    required: false
    default: Debug
  workspace-path:
    description: Optional path to .xcworkspace
    required: false
  project-path:
    description: Optional path to .xcodeproj
    required: false
  derived-data-path:
    description: DerivedData path relative to working-directory
    required: false
    default: build/ios/DerivedData
  artifact-prefix:
    description: Prefix for artifact naming
    required: false
    default: rn-ios-simulator
  custom-identifier:
    description: Optional stable identifier (PR number, channel, etc.)
    required: false
  artifact-retention-days:
    description: GitHub artifact retention
    required: false
    default: "7"

outputs:
  artifact-name:
    description: Uploaded artifact name
    value: ${{ steps.names.outputs.artifact_name }}
  artifact-id:
    description: Uploaded artifact id
    value: ${{ steps.upload.outputs.artifact-id }}
  artifact-url:
    description: Uploaded artifact URL
    value: ${{ steps.upload.outputs.artifact-url }}

runs:
  using: composite
  steps:
    - name: Validate inputs
      shell: bash
      run: |
        set -euo pipefail

        if [[ -n "${{ inputs.workspace-path }}" && -n "${{ inputs.project-path }}" ]]; then
          echo "Use workspace-path or project-path, not both"
          exit 1
        fi

    - name: Resolve iOS project settings
      id: resolve
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        set -euo pipefail

        CONFIG_JSON="$(npx react-native config)"
        IOS_SOURCE_DIR="$(printf '%s' "$CONFIG_JSON" | node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(j.project?.ios?.sourceDir || 'ios')")"

        WORKSPACE="${{ inputs.workspace-path }}"
        PROJECT="${{ inputs.project-path }}"

        if [[ -z "$WORKSPACE" && -z "$PROJECT" ]]; then
          WORKSPACE="$(find "$IOS_SOURCE_DIR" -maxdepth 2 -name '*.xcworkspace' | head -n1 || true)"
          PROJECT="$(find "$IOS_SOURCE_DIR" -maxdepth 2 -name '*.xcodeproj' | head -n1 || true)"
        fi

        if [[ -n "$WORKSPACE" ]]; then
          CONTAINER_KIND="workspace"
          CONTAINER_PATH="$WORKSPACE"
        elif [[ -n "$PROJECT" ]]; then
          CONTAINER_KIND="project"
          CONTAINER_PATH="$PROJECT"
        else
          echo "Could not find .xcworkspace or .xcodeproj"
          exit 1
        fi

        IDENTIFIER="${{ inputs.custom-identifier }}"
        if [[ -z "$IDENTIFIER" ]]; then
          if [[ "${{ github.event_name }}" == "pull_request" ]]; then
            IDENTIFIER="pr-${{ github.event.pull_request.number }}"
          else
            IDENTIFIER="${GITHUB_SHA::7}"
          fi
        fi

        echo "container_kind=$CONTAINER_KIND" >> "$GITHUB_OUTPUT"
        echo "container_path=$CONTAINER_PATH" >> "$GITHUB_OUTPUT"
        echo "identifier=$IDENTIFIER" >> "$GITHUB_OUTPUT"

    - name: Build iOS simulator
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        set -euo pipefail

        if [[ "${{ steps.resolve.outputs.container_kind }}" == "workspace" ]]; then
          XCODE_CONTAINER=( -workspace "${{ steps.resolve.outputs.container_path }}" )
        else
          XCODE_CONTAINER=( -project "${{ steps.resolve.outputs.container_path }}" )
        fi

        xcodebuild \
          "${XCODE_CONTAINER[@]}" \
          -scheme "${{ inputs.scheme }}" \
          -configuration "${{ inputs.configuration }}" \
          -sdk iphonesimulator \
          -destination "generic/platform=iOS Simulator" \
          -derivedDataPath "${{ inputs.derived-data-path }}" \
          CODE_SIGNING_ALLOWED=NO \
          build

    - name: Package simulator app
      id: simulator
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        set -euo pipefail

        PRODUCTS_DIR="${{ inputs.derived-data-path }}/Build/Products"
        CONFIG_PRODUCTS_DIR="$PRODUCTS_DIR/${{ inputs.configuration }}-iphonesimulator"
        SEARCH_DIR="$PRODUCTS_DIR"
        if [[ -d "$CONFIG_PRODUCTS_DIR" ]]; then
          SEARCH_DIR="$CONFIG_PRODUCTS_DIR"
        fi

        # Prefer the app matching the scheme, then deterministic non-test fallbacks.
        APP_PATH="$(find "$SEARCH_DIR" -type d -name "${{ inputs.scheme }}.app" | sort | head -n1 || true)"
        if [[ -z "$APP_PATH" ]]; then
          APP_PATH="$(find "$SEARCH_DIR" -type d -name '*.app' \
            ! -name '*Tests*.app' \
            ! -name '*UITests*.app' \
            ! -name '*-Runner.app' \
            | sort | head -n1 || true)"
        fi
        if [[ -z "$APP_PATH" ]]; then
          APP_PATH="$(find "$SEARCH_DIR" -type d -name '*.app' | sort | head -n1 || true)"
        fi

        if [[ -z "$APP_PATH" ]]; then
          echo "No .app found in $SEARCH_DIR"
          exit 1
        fi

        mkdir -p build/ios
        APP_DIR="$(dirname "$APP_PATH")"
        APP_NAME="$(basename "$APP_PATH")"
        TARBALL="build/ios/${APP_NAME%.app}.app.tar.gz"
        tar -C "$APP_DIR" -czf "$TARBALL" "$APP_NAME"

        echo "artifact_path=$TARBALL" >> "$GITHUB_OUTPUT"

    - name: Build artifact name
      id: names
      shell: bash
      run: |
        set -euo pipefail

        CONFIG="$(echo "${{ inputs.configuration }}" | tr '[:upper:]' '[:lower:]')"
        NAME="${{ inputs.artifact-prefix }}-${CONFIG}-${{ steps.resolve.outputs.identifier }}"
        echo "artifact_name=$NAME" >> "$GITHUB_OUTPUT"

    - name: Upload artifact
      id: upload
      uses: actions/upload-artifact@v4
      with:
        name: ${{ steps.names.outputs.artifact_name }}
        path: ${{ steps.simulator.outputs.artifact_path }}
        if-no-files-found: error
        retention-days: ${{ inputs.artifact-retention-days }}
```

## Common Pitfalls

- Passing both `workspace-path` and `project-path`.
- Uploading `.app` directly instead of `tar.gz` (permission loss risk).
- Using non-macOS runner for iOS jobs.

## Related Skills

- [gha-android-composite-action.md](gha-android-composite-action.md)
- [gha-workflow-and-downloads.md](gha-workflow-and-downloads.md)
