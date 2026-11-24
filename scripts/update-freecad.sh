#!/usr/bin/env bash
# Updates packages/freecad-sources.json to the latest upstream versions:
#   - FreeCAD CAM+ AppImage from the latest Connor9220/FreeCAD release
#   - FreeCAD addon pins (KM-FreeCAD, OpenTheme, SaveAndRestore, SaveUtils)
#
# Safe to run locally or from CI (.github/workflows/update-freecad.yml).
# Requires: curl, jq, nix (with flakes enabled).
# Set GITHUB_TOKEN to avoid GitHub API rate limits (optional locally).
set -euo pipefail

# Work from the repository root (this script lives in scripts/)
cd "$(dirname "$0")/.."
pins=packages/freecad-sources.json

gh_api() {
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/$1"
}

# set_pin <jq assignment using $v> <value>
set_pin() {
  local tmp
  tmp=$(mktemp)
  jq --arg v "$2" "$1" "$pins" >"$tmp"
  mv "$tmp" "$pins"
}

# --------------------------------------------------------------------------
# 1. FreeCAD CAM+ AppImage (latest release of Connor9220/FreeCAD)
# --------------------------------------------------------------------------
release=$(gh_api "repos/Connor9220/FreeCAD/releases/latest")
new_version=$(jq -r '.tag_name' <<<"$release")
new_url=$(jq -r '[.assets[] | select(.name | test("Linux-x86_64.*\\.AppImage$"))][0].browser_download_url' <<<"$release")

if [ -z "$new_version" ] || [ "$new_version" = "null" ] || [ "$new_url" = "null" ]; then
  echo "ERROR: could not determine latest AppImage release/asset" >&2
  exit 1
fi

old_version=$(jq -r '.appimage.version' "$pins")
old_sha256=$(jq -r '.appimage.sha256' "$pins")

if [ "$new_version" != "$old_version" ] || [ -z "$old_sha256" ]; then
  echo "AppImage: $old_version -> $new_version"
  echo "  prefetching $new_url ..."
  new_sha256=$(nix-prefetch-url "$new_url")
  set_pin '.appimage.version = $v' "$new_version"
  set_pin '.appimage.url = $v' "$new_url"
  set_pin '.appimage.sha256 = $v' "$new_sha256"
else
  echo "AppImage: up to date ($old_version)"
fi

# --------------------------------------------------------------------------
# 2. Addon pins (latest commit on the pinned branch)
# --------------------------------------------------------------------------
# update_repo <jq path to the pin object, e.g. .addons.OpenTheme>
update_repo() {
  local path="$1"
  local type owner repo branch old_rev old_hash new_rev tar_url new_hash

  type=$(jq -r "$path.type" "$pins")
  owner=$(jq -r "$path.owner" "$pins")
  repo=$(jq -r "$path.repo" "$pins")
  branch=$(jq -r "$path.branch" "$pins")
  old_rev=$(jq -r "$path.rev" "$pins")
  old_hash=$(jq -r "$path.hash" "$pins")

  if [ "$type" = "codeberg" ]; then
    new_rev=$(curl -fsSL "https://codeberg.org/api/v1/repos/$owner/$repo/branches/$branch" | jq -r '.commit.id')
    tar_url="https://codeberg.org/$owner/$repo/archive/$new_rev.tar.gz"
  else
    new_rev=$(gh_api "repos/$owner/$repo/commits/$branch" | jq -r '.sha')
    tar_url="https://github.com/$owner/$repo/archive/$new_rev.tar.gz"
  fi

  if [ -z "$new_rev" ] || [ "$new_rev" = "null" ]; then
    echo "ERROR: could not determine latest commit for $owner/$repo" >&2
    exit 1
  fi

  if [ "$new_rev" = "$old_rev" ] && [ -n "$old_hash" ]; then
    echo "$owner/$repo: up to date (${old_rev:0:7})"
    return
  fi

  echo "$owner/$repo: ${old_rev:0:7} -> ${new_rev:0:7}"
  echo "  prefetching $tar_url ..."
  new_hash=$(nix flake prefetch --json "$tar_url" | jq -r '.hash')
  set_pin "$path.rev = \$v" "$new_rev"
  set_pin "$path.hash = \$v" "$new_hash"
}

update_repo '.kmFreecad'
for name in $(jq -r '.addons | keys[]' "$pins"); do
  update_repo ".addons.\"$name\""
done

echo "Done. Review changes with: git diff packages/freecad-sources.json"
