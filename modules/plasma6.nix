{ config, pkgs, inputs, ... }:

let
  # Nix copies this file into the store, giving SDDM an absolute,
  # readable path instead of a repository-relative path.
  loginBackground = ../assets/km-laptop-background.jpg;

  # Breeze reads this file in addition to its default theme.conf.
  breezeLoginThemeOverride = pkgs.writeTextDir
    "share/sddm/themes/breeze/theme.conf.user"
    ''
      [General]
      background=${loginBackground}
    '';
in
{

  # Enable SDDM and set theme
  services.displayManager.sddm = {
    enable = true;
    theme = "breeze";
  };

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;

  # Install the Breeze SDDM theme override into:
  # /run/current-system/sw/share/sddm/themes/breeze/theme.conf.user
  environment.systemPackages = [
    breezeLoginThemeOverride
  ];

  # Disable some KDE packages.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    discover
  ];

  # KMail, Kontact, and Merkuro come from the KDE PIM suite, which Plasma 6
  # enables by default. It must be disabled here instead of via excludePackages.
  programs.kde-pim.enable = false;
}
