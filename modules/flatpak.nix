{ inputs, config, pkgs, ... }:
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
