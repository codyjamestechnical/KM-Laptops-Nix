{ inputs, config, pkgs, ... }:
let
  # KM-Laser Inkscape extension bundle, exposed to the Inkscape flatpak below.
  km-laser = pkgs.callPackage ../packages/km-laser.nix { src = inputs.km-laser; };
in
{
  # Declaratively manage flatpak apps via nix-flatpak.
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      rec {
        appId = "io.github.meerk40t.meerk40t";
        sha256 = "5ced7ffe4bfb5633e9ff096cbb8b215af7209a6d1c8b1b776be334921719d13e";
        bundle = "${pkgs.fetchurl {
          url = "https://github.com/jondale/meerk40t/releases/download/0.9.9040.30/MeerK40t-linux-30.flatpak";
          inherit sha256;
        }}";
      }
      "org.kicad.KiCad"
      "cc.arduino.IDE2"
      "org.inkscape.Inkscape"
      "org.gimp.GIMP"
      "org.libreoffice.LibreOffice"
      "com.prusa3d.PrusaSlicer"
      "org.videolan.VLC"
      "com.transmissionbt.Transmission"
    ];

    # Make the KM-Laser extensions available to all users inside the
    # Inkscape flatpak: bind-mount the Nix store path into the sandbox
    # and point Inkscape's extensions directory override at it.
    # Note: this replaces the per-user extensions directory, so users
    # can't additionally install their own extensions via the GUI.
    overrides = {
      "org.inkscape.Inkscape" = {
        Context.filesystems = [
          "${km-laser}/share/inkscape/extensions:ro"
        ];
        Environment.INKSCAPE_EXTENSIONS_DIR = "${km-laser}/share/inkscape/extensions";
      };
    };
  };
}
