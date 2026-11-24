{ lib, appimageTools, fetchurl, fetchFromGitHub, fetchFromGitea, writeShellScript, }:
let
  pname = "freecad";

  # All versions, revisions, and hashes live in freecad-sources.json so they
  # can be bumped automatically by scripts/update-freecad.sh (run manually or
  # via the .github/workflows/update-freecad.yml action).
  sources = lib.importJSON ./freecad-sources.json;

  version = sources.appimage.version;

  src = fetchurl {
    url = sources.appimage.url;
    sha256 = sources.appimage.sha256;
  };

  appimageContents = appimageTools.extract { inherit pname version src; };

  # ---------------------------------------------------------------------------
  # Addons from https://wiki.knoxmakers.org/FreeCAD (NibblerBOT + Additional Addons)
  #
  # These are seeded/synced into the user's ~/.local/share/FreeCAD/Mod directory
  # by the launcher script below. They have to live there (writable, per-user)
  # rather than in the read-only Nix store because:
  #   - KM-FreeCAD self-updates: its Init.py overwrites its own addon directory
  #     with the latest GitHub zip on every FreeCAD start, and its install.py
  #     syncs the NibblerBOT tool library into ~/Documents/FreeCAD.
  #   - OpenTheme is a preference-pack addon; FreeCAD only discovers themes in
  #     the user Mod directory.
  # ---------------------------------------------------------------------------

  fetchAddon = name: pin:
    let
      args = {
        name = "freecad-addon-${name}";
        inherit (pin) owner repo rev;
        # Empty hash in the JSON means "not prefetched yet"; fakeHash makes the
        # build fail with the real hash in the error message.
        hash = if pin.hash == "" then lib.fakeHash else pin.hash;
      };
    in
    if pin.type == "codeberg"
    then fetchFromGitea (args // { domain = "codeberg.org"; })
    else fetchFromGitHub args;

  # Knox Makers addon for the NibblerBOT CNC. Seeded once; afterwards it keeps
  # itself synced with GitHub on every FreeCAD start, so this pin is only the
  # initial version.
  kmFreecad = fetchAddon "KM-FreeCAD" sources.kmFreecad;

  # Pinned addons: reinstalled into the user's Mod directory whenever the
  # pinned revision changes.
  pinnedAddons = lib.mapAttrs fetchAddon sources.addons;

  # FreeCAD 1.1+ (including this CAM+ build) keeps user data in a per-version
  # directory, e.g. ~/.local/share/FreeCAD/v1-1, and only uses the legacy
  # unversioned ~/.local/share/FreeCAD layout for profiles that predate it.
  # Only the leading digits of each component matter (strips "cam+N" suffixes).
  digits = s: lib.head (builtins.match "([0-9]+).*" s);
  versionedDir = "v${digits (lib.versions.major version)}-${digits (lib.versions.minor version)}";

  # Launcher that syncs the addons into the per-user Mod directory, then execs
  # the real (AppImage-wrapped) FreeCAD sitting next to it as .freecad-wrapped.
  launcher = writeShellScript "freecad-with-km-addons" ''
    set -eu

    base="''${FREECAD_USER_DATA:-''${XDG_DATA_HOME:-$HOME/.local/share}/FreeCAD}"

    # sync_addon <mod_dir> <name> <store path>
    #
    # Pinned addons: reinstall only when the pinned store path changes.
    # (A .nix-pin stamp inside the addon records the installed pin; if the
    # Addon Manager removes or reinstalls the addon, the pinned version is
    # restored on the next launch.)
    sync_addon() {
      mod_dir="$1"
      name="$2"
      store="$3"
      stamp="$mod_dir/$name/.nix-pin"
      if [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$store" ]; then
        rm -rf "$mod_dir/''${name:?}"
        cp -r --no-preserve=mode,ownership "$store" "$mod_dir/$name"
        printf '%s\n' "$store" > "$stamp"
      fi
    }

    # sync_mod_dir <mod_dir>
    sync_mod_dir() {
      mod_dir="$1"
      mkdir -p "$mod_dir"

      # KM-FreeCAD: seed once, never overwrite afterwards -- the addon keeps
      # itself up to date from GitHub on every FreeCAD start.
      if [ ! -e "$mod_dir/KM-FreeCAD" ]; then
        cp -r --no-preserve=mode,ownership ${kmFreecad} "$mod_dir/KM-FreeCAD"
      fi

      ${lib.concatStringsSep "\n      " (lib.mapAttrsToList
        (name: addonSrc: ''sync_addon "$mod_dir" "${name}" "${addonSrc}"'')
        pinnedAddons)}
    }

    # Versioned layout used by this FreeCAD version (created if missing)...
    sync_mod_dir "$base/${versionedDir}/Mod"
    # ...plus the legacy unversioned layout, if this machine already has one.
    if [ -d "$base/Mod" ]; then
      sync_mod_dir "$base/Mod"
    fi

    here="$(dirname "$(readlink -f "$0")")"
    exec "$here/.freecad-wrapped" "$@"
  '';
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Hide the real binary behind the addon-syncing launcher
    mv $out/bin/freecad $out/bin/.freecad-wrapped
    install -Dm555 ${launcher} $out/bin/freecad

    install -Dm444 ${appimageContents}/org.freecad.FreeCAD.desktop -t $out/share/applications
    install -Dm444 ${appimageContents}/org.freecad.FreeCAD.svg -t $out/share/icons/hicolor/scalable/apps
    substituteInPlace $out/share/applications/org.freecad.FreeCAD.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=freecad'
  '';

  meta = {
    description = "3D Parametric Modeler";
    homepage = "https://github.com/FreeCAD/FreeCAD";
    downloadPage = "https://github.com/FreeCAD/FreeCAD/releases";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "freecad";
  };
}
