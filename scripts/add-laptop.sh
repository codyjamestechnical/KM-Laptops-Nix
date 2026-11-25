#!/usr/bin/env bash
#
# add-laptop.sh - add a new laptop to the KM-Laptops-Nix fleet.
#
# Run from anywhere inside your clone of the repo:
#
#   ./scripts/add-laptop.sh
#
# It asks what to call the new laptop, then:
#   1. creates hosts/<name>/default.nix from the template in readme.md
#   2. adds the matching nixosConfigurations entry to flake.nix
#   3. commits both as "Added <name> to fleet" and pushes to main
#
# After that: install NixOS on the laptop (username kmadmin, erase the whole
# disk) and run scripts/provision-laptop.sh on it.
set -euo pipefail

DEFAULT_ARCH="x86_64-linux"
DEFAULT_HW_MODULE="lenovo-thinkpad-t14s"
HW_LIST_URL="https://github.com/NixOS/nixos-hardware"

say()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

tmp_files=()
new_tmp() { local f; f=$(mktemp) || die "couldn't create a temp file"; tmp_files+=("$f"); printf '%s' "$f"; }
cleanup() { if [ ${#tmp_files[@]} -gt 0 ]; then rm -f "${tmp_files[@]}"; fi; }
trap cleanup EXIT

# --------------------------------------------------------------- the repo ---
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) \
  || die "not inside a git repository - run this from your KM-Laptops-Nix clone"
cd "$repo_root"
[ -f flake.nix ] || die "$repo_root has no flake.nix - is this the KM-Laptops-Nix repo?"
[ -d hosts ]     || die "$repo_root has no hosts/ directory"

# --------------------------------------------------------- laptop details ---
printf 'Name for the new laptop (e.g. KM-Laptop-02): '
read -r laptop || die "no name given"
laptop=${laptop//[[:space:]]/}

if [ -z "$laptop" ]; then
  die "no name given"
fi
if [[ ! $laptop =~ ^[A-Za-z][A-Za-z0-9-]{0,62}$ || $laptop == *- ]]; then
  die "'$laptop' isn't usable as a hostname: letters, digits and '-' only, must start with a letter, end with a letter or digit, 63 characters max"
fi
if [ -e "hosts/$laptop" ]; then
  die "hosts/$laptop already exists"
fi
if grep -qE "^[[:space:]]*${laptop}[[:space:]]*=" flake.nix; then
  die "flake.nix already has an entry for $laptop"
fi

read -rp "Architecture [$DEFAULT_ARCH]: " arch
arch=${arch:-$DEFAULT_ARCH}
if [[ ! $arch =~ ^[A-Za-z0-9_]+-linux$ ]]; then
  die "'$arch' doesn't look like a nix system string (e.g. x86_64-linux, aarch64-linux)"
fi

read -rp "nixos-hardware module [$DEFAULT_HW_MODULE] (list: $HW_LIST_URL): " hw_module
hw_module=${hw_module:-$DEFAULT_HW_MODULE}
if [[ ! $hw_module =~ ^[A-Za-z0-9._-]+$ ]]; then
  die "'$hw_module' isn't a valid nixos-hardware module name"
fi

# Borrow stateVersion from an existing host so the new one matches the fleet.
state_version=""
for f in hosts/*/default.nix; do
  [ -f "$f" ] || continue
  found=$(grep -m1 -oE 'system\.stateVersion[[:space:]]*=[[:space:]]*"[^"]+"' "$f" 2>/dev/null \
            | sed -E 's/.*"([^"]+)"$/\1/') || true
  if [ -n "${found:-}" ]; then state_version=$found; break; fi
done
state_version=${state_version:-26.05}

# -------------------------------------------------- hosts/<name>/default.nix --
say ""
say "==> creating hosts/$laptop/default.nix (stateVersion $state_version)"
mkdir -p "hosts/$laptop"
cat >"hosts/$laptop/default.nix" <<'NIX'
{inputs, config, pkgs, ...}:
{
  networking.hostName = "@LAPTOP@"; # must match this folder's name and the flake.nix entry

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "@STATE_VERSION@"; # Did you read the comment?
}
NIX
sed -i "s/@LAPTOP@/$laptop/; s/@STATE_VERSION@/$state_version/" "hosts/$laptop/default.nix"

# ------------------------------------------------------------- flake.nix ----
say "==> adding $laptop to nixosConfigurations in flake.nix"
flake_backup=$(new_tmp)
cp flake.nix "$flake_backup"
rollback() {
  warn "reverting flake.nix and removing hosts/$laptop"
  cp "$flake_backup" flake.nix
  rm -rf "hosts/$laptop"
}

block_file=$(new_tmp)
cat >"$block_file" <<'NIX'
      @LAPTOP@ = nixpkgs.lib.nixosSystem {
        system = "@ARCH@"; # match the laptop's architecture (x86_64-linux / aarch64-linux)
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.@HW_MODULE@ # see @HW_LIST_URL@
          ./hosts/@LAPTOP@
          ./modules/core-config.nix
        ];
      };
NIX
sed -i "s|@LAPTOP@|$laptop|g; s|@ARCH@|$arch|; s|@HW_MODULE@|$hw_module|; s|@HW_LIST_URL@|$HW_LIST_URL|" "$block_file"

new_flake=$(new_tmp)
awk -v BLOCK="$block_file" '
  BEGIN { while ((getline l < BLOCK) > 0) blk = blk l "\n"; close(BLOCK) }
  function count(s,   o, c) { o = gsub(/\{/, "", s); c = gsub(/\}/, "", s); return o - c }
  {
    line = $0
    sub(/#.*/, "", line)
    gsub(/"[^"]*"/, "\"\"", line)
    if (!started) {
      if (line ~ /nixosConfigurations[[:space:]]*=/) { started = 1; found = 1; depth = count(line) }
      print; next
    }
    depth += count(line)
    if (depth == 0) { printf "%s", blk; started = 0 }
    print
  }
  END { if (!found) exit 3 }
' flake.nix >"$new_flake" || { rollback; die "couldn't find the nixosConfigurations block in flake.nix"; }
mv "$new_flake" flake.nix

if command -v nix-instantiate >/dev/null 2>&1; then
  say "==> checking that the new files parse"
  nix-instantiate --parse "hosts/$laptop/default.nix" >/dev/null \
    || { rollback; die "hosts/$laptop/default.nix didn't parse - nothing was committed"; }
  nix-instantiate --parse flake.nix >/dev/null \
    || { rollback; die "flake.nix didn't parse after the edit - nothing was committed"; }
else
  warn "nix-instantiate not found - skipping the syntax check"
fi

# --------------------------------------------------------------- review -----
say ""
say "==> flake.nix"
git --no-pager diff -- flake.nix || true
say ""
say "==> hosts/$laptop/default.nix"
sed 's/^/    /' "hosts/$laptop/default.nix"

printf '\nCommit as "Added %s to fleet" and push to main? [Y/n] ' "$laptop"
read -r reply || reply=""
case ${reply:-y} in
  [Yy]*) ;;
  *) say "nothing committed - the files are in place, commit them yourself when ready."; exit 0 ;;
esac

# ---------------------------------------------------------------- commit ----
git add -- "hosts/$laptop/default.nix" flake.nix
git commit -m "Added $laptop to fleet" -- "hosts/$laptop/default.nix" flake.nix

if ! git remote get-url origin >/dev/null 2>&1; then
  warn "no 'origin' remote configured - the commit is local only, push it yourself"
  exit 1
fi

say "==> pushing to origin/main"
if ! git push origin HEAD:main; then
  warn "push failed. Try: git pull --rebase origin main && git push origin HEAD:main"
  exit 1
fi

say ""
say "Done: $laptop is in the fleet ($(git rev-parse --short HEAD))."
say ""
say "Next:"
say "  1. install NixOS on the laptop - username kmadmin, standard admin password, erase the whole disk"
say "  2. on the laptop, run scripts/provision-laptop.sh (see the one-liner in its header)"
