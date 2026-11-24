{ config, pkgs, inputs, ... }:
{
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Disable some KDE packages.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
    ];

  # KMail, Kontact, and Merkuro come from the KDE PIM suite, which Plasma 6
  # enables by default. It must be disabled here instead of via excludePackages.
  programs.kde-pim.enable = false;

}
