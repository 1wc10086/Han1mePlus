#!/usr/bin/env python3
"""Generate the AltStore / SideStore / LiveContainer source JSON for Han1mePlus.

The generated file is `altstore/source.json`. It is committed to the repository so
that users can add this URL once and then install / update the iOS build with one tap:

    https://raw.githubusercontent.com/1wc10086/Han1mePlus/main/altstore/source.json

The script only uses the Python standard library, so it can run both locally and in
GitHub Actions without installing anything:

    python3 altstore/generate.py

Environment variables (all optional):

    REPO          owner/name of the GitHub repository   (default: 1wc10086/Han1mePlus)
    IPA_ASSET     release asset filename to publish     (default: iphone.arm64.ipa)
    REF           git ref used to read pubspec.yaml     (default: main)
    OUTPUT        path of the generated JSON            (default: altstore/source.json)
    GITHUB_TOKEN  raises the GitHub API rate limit when running in CI
    INCLUDE_PRERELEASE=1  also publish GitHub pre-releases
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

# --------------------------------------------------------------------------------------
# Hand maintained metadata. Everything in here is editorial, not derived from releases.
# --------------------------------------------------------------------------------------

REPO = os.environ.get("REPO", "1wc10086/Han1mePlus")
IPA_ASSET = os.environ.get("IPA_ASSET", "iphone.arm64.ipa")
REF = os.environ.get("REF", "main")
OUTPUT = os.environ.get("OUTPUT", "altstore/source.json")
INCLUDE_PRERELEASE = os.environ.get("INCLUDE_PRERELEASE") == "1"
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")

RAW = f"https://raw.githubusercontent.com/{REPO}/{REF}"
LOGO = f"{RAW}/assets/logo.png"

SOURCE_META = {
    "name": "Han1mePlus",
    "subtitle": "Hanime1 第三方客户端（iOS / iPadOS）",
    "description": (
        "Han1mePlus 的 iOS 安装源。\n\n"
        "添加本源后，可以直接在 SideStore / LiveContainer 中一键安装或更新 iOS 版，"
        "无需每次手动去 Releases 页面下载 ipa。\n\n"
        "【重要】\n"
        "· 本应用为非官方第三方客户端，与 Hanime1 官方无任何关联。\n"
        "· 仅供年满 18 周岁的成年人使用。\n"
        "· 下载、安装或运行即视为您已阅读并同意项目 LICENSE 与免责声明。\n"
        "· 仓库发布的 ipa 未签名，SideStore / LiveContainer 会使用您自己的证书重新签名。"
    ),
    "iconURL": LOGO,
    "website": f"https://github.com/{REPO}",
    "tintColor": "#6750A4",
    "nsfw": True,
    "identifier": "com.liar.han1meplus.source",
}

APP_META = {
    "name": "Han1me+",
    "bundleIdentifier": "com.liar.han1mePlus",
    "developerName": "1wc10086",
    "subtitle": "Hanime1 第三方客户端",
    "localizedDescription": (
        "基于 Material Design 3 设计语言，使用 Dart & Flutter 构建的 Hanime1 第三方客户端。\n\n"
        "支持 Android、iOS、macOS、Windows 与 Linux；本源仅提供 iOS（iphone.arm64）版本。\n\n"
        "本应用为非官方客户端。使用者须自负合规审查责任，确保自身行为符合所访问平台的"
        "服务条款及适用法律。本应用仅供年满 18 周岁的成年人使用。"
    ),
    "iconURL": LOGO,
    "tintColor": "#6750A4",
    "category": "entertainment",
    # Verified against the ipa published in the v1.2.2 release:
    # the archive is *unsigned* (no embedded.mobileprovision, no _CodeSignature), so the
    # binary carries no entitlements. The only privacy usage description in Info.plist
    # is NSFaceIDUsageDescription.
    "appPermissions": {
        "entitlements": [],
        "privacy": {
            "NSFaceIDUsageDescription": "使用 Face ID 或设备密码解锁 Han1me+",
        },
    },
    "minOSVersion": "15.0",
}

# --------------------------------------------------------------------------------------

VERSION_RE = re.compile(r"^version:\s*([0-9]+(?:\.[0-9]+)*)(?:\+([0-9]+))?\s*$", re.M)


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def request(url: str, raw: bool = False) -> bytes:
    headers = {"User-Agent": "han1meplus-altstore-source", "Accept": "application/vnd.github+json"}
    if GITHUB_TOKEN and "api.github.com" in url:
        headers["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def list_releases() -> list[dict]:
    releases: list[dict] = []
    page = 1
    while True:
        url = f"https://api.github.com/repos/{REPO}/releases?per_page=100&page={page}"
        batch = json.loads(request(url))
        if not batch:
            break
        releases.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    log(f"fetched {len(releases)} releases")
    return releases


def version_at_tag(tag: str) -> tuple[str, str] | None:
    """Read `version: x.y.z+build` from pubspec.yaml at the release tag."""
    try:
        text = request(f"https://raw.githubusercontent.com/{REPO}/{tag}/pubspec.yaml").decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        log(f"  ! {tag}: pubspec.yaml unavailable ({exc.code})")
        return None
    match = VERSION_RE.search(text)
    if not match:
        log(f"  ! {tag}: no parsable version in pubspec.yaml")
        return None
    return match.group(1), match.group(2) or "1"


def version_key(entry: dict) -> tuple:
    """Sort key: highest marketing version + build first, then newest release date."""
    nums = tuple(int(p) for p in entry["version"].split("."))
    return (nums, int(entry["_build"]), entry["date"])


def build_versions(releases: list[dict]) -> list[dict]:
    versions: list[dict] = []
    seen: set[tuple[str, str]] = set()
    for release in releases:
        tag = release.get("tag_name") or ""
        if release.get("draft"):
            continue
        if release.get("prerelease") and not INCLUDE_PRERELEASE:
            continue
        asset = next((a for a in release.get("assets") or [] if a.get("name") == IPA_ASSET), None)
        if asset is None:
            log(f"  - {tag}: no {IPA_ASSET} asset, skipped")
            continue
        parsed = version_at_tag(tag)
        if parsed is None:
            continue
        version, build = parsed
        # AltStore identifies a build by (version, buildVersion); the same marketing
        # version may legitimately appear more than once with different build numbers.
        if (version, build) in seen:
            log(f"  - {tag}: duplicate {version} ({build}), skipped")
            continue
        seen.add((version, build))

        digest = (asset.get("digest") or "").strip()
        entry = {
            "version": version,
            "buildVersion": build,
            "date": release.get("published_at") or release.get("created_at"),
            "localizedDescription": (release.get("body") or f"Han1mePlus {version}").replace("\r\n", "\n").strip(),
            "downloadURL": asset["browser_download_url"],
            "size": asset["size"],
            "minOSVersion": APP_META["minOSVersion"],
            "_build": build,
        }
        if digest.startswith("sha256:"):
            entry["sha256"] = digest[len("sha256:"):]
        versions.append(entry)
        log(f"  + {tag}: {version} ({build}), {asset['size']} bytes")
    versions.sort(key=version_key, reverse=True)
    for entry in versions:
        del entry["_build"]
    return versions


def main() -> int:
    versions = build_versions(list_releases())
    if not versions:
        log("refusing to write an empty source: no usable releases found")
        return 1

    app = dict(APP_META)
    app["versions"] = versions
    source = dict(SOURCE_META)
    source["featuredApps"] = [APP_META["bundleIdentifier"]]
    source["apps"] = [app]
    source["news"] = []

    out = Path(OUTPUT)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(source, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    log(f"wrote {out} with {len(versions)} version(s); latest = {versions[0]['version']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
