---
title: Android Emulator Composite Action (RN CLI)
impact: HIGH
tags: android, emulator, github-actions, react-native, gradle, artifact
---

# Skill: Android Emulator Composite Action (RN CLI)

Composite action template for building React Native Android emulator APKs in GitHub Actions and uploading the resulting artifact.

## Quick Config

1. Create `.github/actions/github-actions/android-build/action.yml`.
2. Copy the template below.
3. Set `variant` (for emulator flows, use `Debug` by default).
4. Use action outputs (`artifact-name`, `artifact-id`, `artifact-url`) in downstream jobs.

## When to Use

- Need cloud Android emulator build artifacts for testing.
- Need configurable debug-style builds from one action.
- Need reliable artifact retrieval through `gh` and REST API.

## Prerequisites

- Linux runner with JDK 17.
- React Native dependencies installed.
- Android SDK and Gradle wrapper available in the repository.

## Template (`.github/actions/github-actions/android-build/action.yml`)

```yaml
name: React Native Android Emulator Build
description: Build React Native Android emulator APK in GitHub Actions and upload artifact

inputs:
  working-directory:
    description: Project root
    required: false
    default: "."
  variant:
    description: Build variant (Debug by default for emulator flows)
    required: false
    default: Debug
  artifact-prefix:
    description: Prefix for artifact naming
    required: false
    default: rn-android-emulator
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
    - name: Resolve Android project settings
      id: resolve
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        set -euo pipefail

        CONFIG_JSON="$(npx react-native config)"
        ANDROID_SOURCE_DIR="$(printf '%s' "$CONFIG_JSON" | node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(j.project?.android?.sourceDir || 'android')")"
        APP_NAME="$(printf '%s' "$CONFIG_JSON" | node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync(0,'utf8'));process.stdout.write(j.project?.android?.appName || 'app')")"

        IDENTIFIER="${{ inputs.custom-identifier }}"
        if [[ -z "$IDENTIFIER" ]]; then
          if [[ "${{ github.event_name }}" == "pull_request" ]]; then
            IDENTIFIER="pr-${{ github.event.pull_request.number }}"
          else
            IDENTIFIER="${GITHUB_SHA::7}"
          fi
        fi

        echo "android_source_dir=$ANDROID_SOURCE_DIR" >> "$GITHUB_OUTPUT"
        echo "app_name=$APP_NAME" >> "$GITHUB_OUTPUT"
        echo "identifier=$IDENTIFIER" >> "$GITHUB_OUTPUT"

    - name: Build Android APK
      id: build
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        set -euo pipefail

        VARIANT="${{ inputs.variant }}"
        VARIANT_LOWER="$(echo "$VARIANT" | tr '[:upper:]' '[:lower:]')"
        GRADLE_TASK="assemble${VARIANT}"

        (
          cd "${{ steps.resolve.outputs.android_source_dir }}"
          ./gradlew ":${{ steps.resolve.outputs.app_name }}:${GRADLE_TASK}"
        )

        OUTPUT_ROOT="${{ steps.resolve.outputs.android_source_dir }}/${{ steps.resolve.outputs.app_name }}/build/outputs/apk"
        SEARCH_DIR="$OUTPUT_ROOT"
        if [[ -d "$OUTPUT_ROOT/$VARIANT_LOWER" ]]; then
          SEARCH_DIR="$OUTPUT_ROOT/$VARIANT_LOWER"
        fi

        APK_PATH="$(find "$SEARCH_DIR" -type f -name '*.apk' ! -name '*androidTest*' | sort | head -n1 || true)"
        if [[ -z "$APK_PATH" ]]; then
          APK_PATH="$(find "$OUTPUT_ROOT" -type f -name '*.apk' ! -name '*androidTest*' | sort | head -n1 || true)"
        fi

        if [[ -z "$APK_PATH" ]]; then
          echo "No Android APK found"
          exit 1
        fi

        echo "apk_path=$APK_PATH" >> "$GITHUB_OUTPUT"

    - name: Build artifact name
      id: names
      shell: bash
      run: |
        set -euo pipefail

        VARIANT="$(echo "${{ inputs.variant }}" | tr '[:upper:]' '[:lower:]')"
        NAME="${{ inputs.artifact-prefix }}-${VARIANT}-${{ steps.resolve.outputs.identifier }}"
        echo "artifact_name=$NAME" >> "$GITHUB_OUTPUT"

    - name: Upload artifact
      id: upload
      uses: actions/upload-artifact@v4
      with:
        name: ${{ steps.names.outputs.artifact_name }}
        path: ${{ steps.build.outputs.apk_path }}
        if-no-files-found: error
        retention-days: ${{ inputs.artifact-retention-days }}
```

## Common Pitfalls

- Lowercase `variant` values causing wrong Gradle task names.
- Missing JDK setup in caller workflow.
- Hardcoding module name to `app` when `react-native config` reports a custom `appName`.

## Related Skills

- [gha-ios-composite-action.md](gha-ios-composite-action.md)
- [gha-workflow-and-downloads.md](gha-workflow-and-downloads.md)
