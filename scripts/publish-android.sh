#!/usr/bin/env bash
# [EN] Publishes the Android library of CYLTabBarController (Example-Android: `cyltabbar` and the `tabpages` module it
#      depends on) with Gradle, to a Maven repository:
#        local    ~/.m2 (Maven Local), to try the artifacts in another project. Default.
#        staging  Example-Android/build/staging-deploy and a Maven Central bundle (zip), checked; nothing is uploaded.
#        central  staging, then uploads the bundle to Maven Central (the Central Portal) and waits for its validation.
#        github   GitHub Packages (a Maven repository of the GitHub repository).
#      Artifacts: io.github.chenyilong:cyltabbarcontroller (aar) and io.github.chenyilong:cyltabbarcontroller-pages
#      (jar), with sources, javadoc, the POM and the Gradle module metadata. The version follows CYLTabBarController.podspec.
# [CN] 用 Gradle 把 CYLTabBarController 的 Android 库（Example-Android：`cyltabbar` 及其依赖的 `tabpages` 模块）发布到 Maven 仓库：
#        local    ~/.m2（Maven Local），在其他工程中试用。默认。
#        staging  Example-Android/build/staging-deploy 与 Maven Central 上传包（zip），并做检查；不上传。
#        central  先 staging，再把上传包上传到 Maven Central（Central Portal）并等待校验。
#        github   GitHub Packages（GitHub 仓库的 Maven 仓库）。
#      产物：io.github.chenyilong:cyltabbarcontroller（aar）与 io.github.chenyilong:cyltabbarcontroller-pages（jar），带源码、javadoc、
#      POM 与 Gradle 模块元数据。版本默认与 CYLTabBarController.podspec 一致。
#
# Usage 用法:
#   scripts/publish-android.sh [local|staging|central|github] [options]
#     --version X        [EN] version to publish (default: the podspec's). [CN] 发布的版本（默认与 podspec 一致）。
#     --group G          [EN] Maven group (default: io.github.chenyilong). [CN] Maven group（默认 io.github.chenyilong）。
#     --skip-tests       [EN] do not run the unit tests and lint first. [CN] 不先运行单元测试与 lint。
#     --automatic        [EN] central: publish right after validation (default: wait for "Publish" on central.sonatype.com).
#                        [CN] central：校验通过后自动发布（默认在 central.sonatype.com 上手动点击 "Publish"）。
#     --dry-run          [EN] print the Gradle and upload commands only. [CN] 只打印 Gradle 与上传命令。
#
# Environment 环境变量:
#   central:  MAVEN_CENTRAL_USERNAME, MAVEN_CENTRAL_PASSWORD  [EN] a Central Portal user token. [CN] Central Portal 的用户令牌。
#             SIGNING_KEY (ASCII-armored private key), SIGNING_PASSWORD, or gpg with -Psigning.gnupg.keyName in
#             ~/.gradle/gradle.properties. [CN] 签名私钥（ASCII 格式）与密码，或在 ~/.gradle/gradle.properties 中配置 gpg。
#   github:   GITHUB_ACTOR, GITHUB_TOKEN (write:packages), optional GITHUB_REPOSITORY (owner/name).
#
# [EN] Maven Central needs the group's namespace verified once on central.sonatype.com (io.github.<user> is verified with
#      the GitHub account), and every artifact signed: `central` stops before uploading when a signature is missing.
# [CN] Maven Central 需要先在 central.sonatype.com 验证一次 group 的命名空间（io.github.<用户名> 通过 GitHub 账号验证），且每个产物都要签名：
#      缺少签名时 `central` 在上传前停止。
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROJECT="$ROOT/Example-Android"
STAGING="$PROJECT/build/staging-deploy"
BUNDLE="$PROJECT/build/cyltabbarcontroller-central-bundle.zip"
CENTRAL_API="https://central.sonatype.com/api/v1/publisher"

TARGET=local
VERSION=""
GROUP=""
SKIP_TESTS=0
PUBLISHING_TYPE=USER_MANAGED
DRY_RUN=0

die() { echo "publish-android: $*" >&2; exit 1; }
step() { echo "== $*"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        local|staging|central|github) TARGET=$1 ;;
        --version) VERSION=${2:?--version needs a value}; shift ;;
        --group) GROUP=${2:?--group needs a value}; shift ;;
        --skip-tests) SKIP_TESTS=1 ;;
        --automatic) PUBLISHING_TYPE=AUTOMATIC ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
        *) die "unknown argument: $1 (see --help)" ;;
    esac
    shift
done

# [EN] Gradle: the project's wrapper when there is one, else gradle on the PATH. A UTF-8 locale is needed by the example
#      modules' asset names (see docs/Android-Examples.md).
# [CN] Gradle：有 wrapper 时用 wrapper，否则用 PATH 中的 gradle。示例模块的资源名需要 UTF-8 locale（见 docs/Android-Examples.md）。
if [[ -x "$PROJECT/gradlew" ]]; then GRADLE="$PROJECT/gradlew"; else GRADLE=$(command -v gradle) || die "gradle not found (install Gradle 8.9+ or add a wrapper)"; fi
export LC_ALL=${LC_ALL:-C.UTF-8}
GRADLE_ARGS=(-p "$PROJECT" --console=plain)
[[ -n "$VERSION" ]] && GRADLE_ARGS+=("-PcylVersion=$VERSION")
[[ -n "$GROUP" ]] && GRADLE_ARGS+=("-PcylGroup=$GROUP")
MODULES=(:tabpages :cyltabbar)

run() {
    echo "+ $*"
    [[ "$DRY_RUN" = 1 ]] || "$@"
}

gradle_tasks() {
    local tasks=()
    for module in "${MODULES[@]}"; do tasks+=("$module:$1"); done
    run "$GRADLE" "${GRADLE_ARGS[@]}" "${tasks[@]}"
}

if [[ -z "$VERSION" ]]; then
    VERSION=$(sed -nE "s/^[[:space:]]*s\.version[[:space:]]*=[[:space:]]*[\"']([^\"']+)[\"'].*/\1/p" "$ROOT/CYLTabBarController.podspec" | head -1)
fi
GROUP_PATH=$(echo "${GROUP:-io.github.chenyilong}" | tr . /)
step "CYLTabBarController for Android $VERSION -> $TARGET"
case "$VERSION" in
    *SNAPSHOT*) [[ "$TARGET" = central ]] && die "Maven Central does not take SNAPSHOT versions" ;;
    *) ;;
esac

# 1. [EN] Tests and lint, as CI would. [CN] 与 CI 一样先运行测试与 lint。
if [[ "$SKIP_TESTS" = 0 ]]; then
    step "Tests and lint 测试与 lint"
    run "$GRADLE" "${GRADLE_ARGS[@]}" :tabpages:test :cyltabbar:testDebugUnitTest :cyltabbar:lintRelease
fi

# 2. [EN] Credentials before any work that depends on them. [CN] 先检查凭据。
if [[ "$TARGET" = central ]] && [[ "$DRY_RUN" = 0 ]]; then
    if [[ -z "${MAVEN_CENTRAL_USERNAME:-}" ]] || [[ -z "${MAVEN_CENTRAL_PASSWORD:-}" ]]; then
        die "set MAVEN_CENTRAL_USERNAME and MAVEN_CENTRAL_PASSWORD (a Central Portal user token)"
    fi
    [[ -n "${SIGNING_KEY:-}" ]] || grep -qs '^signing.gnupg.keyName' "${GRADLE_USER_HOME:-$HOME/.gradle}/gradle.properties" || die "set SIGNING_KEY (and SIGNING_PASSWORD), or signing.gnupg.keyName in ~/.gradle/gradle.properties"
fi
if [[ "$TARGET" = github && "$DRY_RUN" = 0 && ( -z "${GITHUB_ACTOR:-}" || -z "${GITHUB_TOKEN:-}" ) ]]; then
    die "set GITHUB_ACTOR and GITHUB_TOKEN (with write:packages)"
fi

# 3. [EN] Publish. [CN] 发布。
case "$TARGET" in
    local)
        step "Maven Local (~/.m2)"
        gradle_tasks publishToMavenLocal
        echo "Use it with: repositories { mavenLocal() }  dependencies { implementation(\"${GROUP:-io.github.chenyilong}:cyltabbarcontroller:$VERSION\") }"
        exit 0 ;;
    github)
        step "GitHub Packages"
        gradle_tasks publishAllPublicationsToGitHubPackagesRepository
        echo "Published to https://maven.pkg.github.com/${GITHUB_REPOSITORY:-ChenYilong/CYLTabBarController}"
        exit 0 ;;
    *) ;;
esac

step "Staging repository $STAGING"
run rm -rf "$STAGING" "$BUNDLE"
gradle_tasks publishAllPublicationsToStagingRepository
[[ "$DRY_RUN" = 1 ]] && { echo "+ (check the bundle, zip it, upload it to $CENTRAL_API/upload)"; exit 0; }

# 4. [EN] Check what Maven Central requires, for both artifacts. [CN] 检查 Maven Central 对两个产物的要求。
step "Checking the bundle 检查上传包"
problems=0
for artifact in cyltabbarcontroller cyltabbarcontroller-pages; do
    folder="$STAGING/$GROUP_PATH/$artifact/$VERSION"
    main=aar; [[ "$artifact" = cyltabbarcontroller-pages ]] && main=jar
    for file in "$artifact-$VERSION.$main" "$artifact-$VERSION.pom" "$artifact-$VERSION-sources.jar" "$artifact-$VERSION-javadoc.jar"; do
        [[ -f "$folder/$file" ]] || { echo "missing: $artifact/$VERSION/$file"; problems=$((problems + 1)); continue; }
        for checksum in md5 sha1; do
            [[ -f "$folder/$file.$checksum" ]] || { echo "missing: $file.$checksum"; problems=$((problems + 1)); }
        done
        if [[ ! -f "$folder/$file.asc" ]]; then
            if [[ "$TARGET" = central ]]; then echo "not signed: $file"; problems=$((problems + 1)); else echo "not signed (fine for staging): $file"; fi
        fi
    done
    for tag in "<name>" "<description>" "<url>" "<license>" "<developer>" "<scm>"; do
        grep -q "$tag" "$folder/$artifact-$VERSION.pom" 2>/dev/null || { echo "POM without $tag: $artifact"; problems=$((problems + 1)); }
    done
done
[[ "$problems" = 0 ]] || die "$problems problem(s) in the bundle"

# [EN] The bundle: the repository layout, without maven-metadata.xml (the Central Portal makes its own).
# [CN] 上传包：仓库目录结构，不含 maven-metadata.xml（Central Portal 会自己生成）。
python3 - "$STAGING" "$BUNDLE" <<'PY'
import os, sys, zipfile
staging, bundle = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(bundle, 'w', zipfile.ZIP_DEFLATED) as archive:
    for folder, _, files in os.walk(staging):
        for name in sorted(files):
            if name.startswith('maven-metadata.xml'):
                continue
            path = os.path.join(folder, name)
            archive.write(path, os.path.relpath(path, staging))
print('bundle: %s (%d files)' % (bundle, len(zipfile.ZipFile(bundle).namelist())))
PY
[[ "$TARGET" = staging ]] && exit 0

# 5. [EN] Upload to the Central Portal, then wait for its validation. [CN] 上传到 Central Portal，并等待校验。
step "Uploading to Maven Central ($PUBLISHING_TYPE)"
TOKEN=$(printf '%s:%s' "$MAVEN_CENTRAL_USERNAME" "$MAVEN_CENTRAL_PASSWORD" | base64 | tr -d '\n')
DEPLOYMENT=$(curl --fail-with-body -sS -X POST -H "Authorization: Bearer $TOKEN" \
    -F "bundle=@$BUNDLE" "$CENTRAL_API/upload?name=cyltabbarcontroller-$VERSION&publishingType=$PUBLISHING_TYPE") || die "upload failed: $DEPLOYMENT"
echo "deployment: $DEPLOYMENT"
for attempt in $(seq 1 60); do
    sleep 10
    STATUS=$(curl --fail-with-body -sS -X POST -H "Authorization: Bearer $TOKEN" "$CENTRAL_API/status?id=$DEPLOYMENT") || die "status check failed: $STATUS"
    STATE=$(printf '%s' "$STATUS" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("deploymentState", ""))')
    echo "[$attempt] $STATE"
    case "$STATE" in
        VALIDATED) echo "Validated: publish it on https://central.sonatype.com/publishing/deployments"; exit 0 ;;
        PUBLISHING|PUBLISHED) echo "Published: https://central.sonatype.com/artifact/${GROUP:-io.github.chenyilong}/cyltabbarcontroller/$VERSION"; exit 0 ;;
        FAILED) printf '%s\n' "$STATUS" >&2; die "Maven Central rejected the deployment" ;;
        *) ;;
    esac
done
die "still not validated after 10 minutes: check https://central.sonatype.com/publishing/deployments"
