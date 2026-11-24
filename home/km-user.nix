{ pkgs, ... }:

let
  # These paths refer to files already present in the repository.
  # Nix copies them into the store and Plasma receives absolute paths.
  menuIcon = ../assets/knox_makers_logo_large_light.svg;
  desktopWallpaper = ../assets/km-laptop-background.jpg;
in
{
  home.username = "kmuser";
  home.homeDirectory = "/home/kmuser";

  # Set this for the initial Home Manager deployment and do not routinely
  # bump it when upgrading packages.
  home.stateVersion = "26.05";

  programs.plasma = {
    enable = true;

    # Apply the wallpaper after themes and panel setup.
    # runAlways also avoids stale Plasma Manager "last run" state.
    startup.startupScript."km-wallpaper" = {
      text = ''
        ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage ${desktopWallpaper}
      '';

      # Theme scripts run at priority 1 and panels at priority 2.
      priority = 4;
      runAlways = true;
    };

    workspace = {
      # Breeze Dark global theme, Plasma style, and color scheme.
      lookAndFeel = "org.kde.breezedark.desktop";
      theme = "breeze-dark";
      colorScheme = "BreezeDark";

    };

    panels = [
      {
        location = "bottom";

        widgets = [
          # Plasma application menu (Kickoff).
          {
            kickoff = {
              icon = "${menuIcon}";
            };
          }

          # Icons-only task manager with the requested pinned launchers.
          {
            iconTasks = {
              launchers = [
                # KDE Dolphin
                "applications:org.kde.dolphin.desktop"

                # Flatpaks
                "applications:org.kicad.KiCad.desktop"

                # NixOS Firefox ESR
                "applications:firefox-esr.desktop"

                # FreeCAD AppImage package
                "applications:org.freecad.FreeCAD.desktop"

                # GIMP
                "applications:org.gimp.GIMP.desktop"

                # Inkscape
                "applications:org.inkscape.Inkscape.desktop"

                # Prusa Slicer
                "applications:com.prusa3d.PrusaSlicer.desktop"

                # Visual Studio Code
                "applications:code.desktop"
              ];
            };
          }

          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];
  };
}
