#!/usr/bin/env bash
#
# provision-laptop.sh - point a freshly installed NixOS laptop at the
# KM-Laptops-Nix flake. This is readme steps 5-7, done in one shot.
#
#   sudo ./scripts/provision-laptop.sh                 # prompts for the name
#   sudo ./scripts/provision-laptop.sh KM-Laptop-02
#   sudo ./scripts/provision-laptop.sh --force KM-Laptop-02
#
# Not on the laptop yet? Pipe it:
#   curl -fsSL https://raw.githubusercontent.com/codyjamestechnical/KM-Laptops-Nix/main/scripts/provision-laptop.sh | sudo bash -s -- KM-Laptop-02
#
# Why this is shorter than the readme: the flake already sets
# nix.settings.experimental-features, so instead of editing
# /etc/nixos/configuration.nix and doing a throwaway nixos-rebuild just to turn
# flakes on, we turn them on for this single invocation via NIX_CONFIG. From
# the first successful switch onwards the flake itself keeps them enabled.
set -euo pipefail

FLAKE="${KM_FLAKE:-github:codyjamestechnical/KM-Laptops-Nix}"
RAW_FLAKE_NIX="https://raw.githubusercontent.com/codyjamestechnical/KM-Laptops-Nix/main/flake.nix"
NIX_CONFIG_VALUE="experimental-features = nix-command flakes"

say()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: provision-laptop.sh [--force] [<laptop-name>]

Provisions this machine from the KM-Laptops-Nix flake.

  <laptop-name>  hostname as it appears in the repo (default: this machine's
                 current hostname)
  -f, --force    skip the pre-flight checks and switch anyway
  -h, --help     show this help

Set KM_FLAKE to use a different flake ref (e.g. a branch).
EOF
}

for arg in "$@"; do
  case $arg in -h|--help) usage; exit 0 ;; esac
done

# ------------------------------------------------------------ be root -------
if [ "$(id -u)" -ne 0 ]; then
  if [ -f "$0" ]; then
    say "==> re-running with sudo"
    exec sudo -- "$0" "$@"
  fi
  die "run this as root (it calls nixos-rebuild switch) - e.g. pipe it through 'sudo bash -s -- <laptop-name>'"
fi

force=0
host=""
for arg in "$@"; do
  case $arg in
    -f|--force) force=1 ;;
    -h|--help)  usage; exit 0 ;;
    -*)         die "unknown option: $arg" ;;
    *)          [ -z "$host" ] || die "only one laptop name, please"; host=$arg ;;
  esac
done

# ------------------------------------------------------------ preflight -----
[ -e /etc/NIXOS ] || die "this doesn't look like NixOS (/etc/NIXOS is missing)"
command -v nixos-rebuild >/dev/null 2>&1 || die "nixos-rebuild not found - is this a NixOS install?"

if ! id -u kmadmin >/dev/null 2>&1; then
  [ "$force" -eq 1 ] || die "there's no 'kmadmin' user - the readme says to install with username kmadmin and the standard admin password, and the flake does not set that password (or re-run with --force)"
  warn "no kmadmin user on this machine"
elif command -v passwd >/dev/null 2>&1; then
  case $(passwd -S kmadmin 2>/dev/null | awk '{print $2}') in
    P)  : ;;
    NP) [ "$force" -eq 1 ] || die "kmadmin has no password - set one with 'passwd kmadmin' first, or re-run with --force (the flake won't set it, so you'd have no admin login)"
        warn "kmadmin has no password" ;;
    L)  warn "kmadmin's password is locked - you won't be able to log in as kmadmin" ;;
  esac
fi

# --------------------------------------------------------- laptop name ------
if [ -z "$host" ]; then
  current=$(uname -n)
  printf 'Name of this laptop as it appears in the repo (e.g. KM-Laptop-02) [%s]: ' "$current"
  read -r host || host=""
  host=${host:-$current}
fi
host=${host//[[:space:]]/}
if [[ ! $host =~ ^[A-Za-z][A-Za-z0-9-]{0,62}$ || $host == *- ]]; then
  die "'$host' isn't a valid hostname: letters, digits and '-' only, must start with a letter, end with a letter or digit"
fi

# Is this laptop actually in the flake yet?
if [ -z "${KM_FLAKE:-}" ] && command -v curl >/dev/null 2>&1; then
  if ! curl -fsSL "$RAW_FLAKE_NIX" | grep -qE "^[[:space:]]*${host}[[:space:]]*="; then
    die "the repo's flake.nix has no entry for $host - run scripts/add-laptop.sh on your admin machine and push first"
  fi
else
  warn "skipping the check that $host exists in the repo's flake.nix"
fi

# ------------------------------------------------- will this thing boot? ----
say "==> checking the flake defines a root filesystem for $host (this takes a moment)"
if ! fs_json=$(NIX_CONFIG="$NIX_CONFIG_VALUE" nix eval --json \
      "$FLAKE#nixosConfigurations.$host.config.fileSystems"); then
  [ "$force" -eq 1 ] || die "couldn't evaluate $FLAKE#$host - fix the error above, or re-run with --force to try the rebuild anyway"
  warn "couldn't evaluate $FLAKE#$host"
elif [ "${fs_json:-}" = "{}" ]; then
  warn "the flake defines no fileSystems for $host - switching now would install"
  warn "a system that can't mount its own root disk."
  warn "add this laptop's disk layout to the flake (a shared storage module, or a"
  warn "hosts/$host/hardware-configuration.nix imported from its default.nix)."
  [ "$force" -eq 1 ] || die "refusing to switch; re-run with --force once that's handled"
fi

# ------------------------------------------------------------- provision ----
say "==> nixos-rebuild switch --refresh --flake $FLAKE#$host"
NIX_CONFIG="$NIX_CONFIG_VALUE" nixos-rebuild switch --refresh --flake "$FLAKE#$host"

if [ "$(uname -n)" = "$host" ]; then
  say "==> hostname is $host"
else
  warn "hostname is $(uname -n) but the flake configures $host"
fi

say ""
say "Done - this laptop is now $host, managed from the repo."
say "Flakes are permanently enabled by the flake config, and core-config.nix"
say "pulls the latest config from GitHub hourly (system.autoUpgrade)."
say "Change things in the repo, not on the laptop."