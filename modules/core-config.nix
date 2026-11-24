{ config, pkgs, inputs, ... }:
{
  imports = [
    ./firefox.nix
    ./flatpak.nix
    ./plasma6.nix
    ./zsh.nix
    ./home-manager.nix
    ../users/km-admin.nix
    ../users/km-user.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable Bluetooth.
  hardware.bluetooth.enable = true;

  # WiFi SSID & Password.
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles = {
    km-wifi = {
      connection = {
        id = "km";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        mode = "infrastructure";
        ssid = "km";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "devil_pig";
      };
    };
  };

  # Set Timezone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Install system packages.
  environment.systemPackages = with pkgs; [
    (callPackage ../packages/freecad.nix { }) # install FreeCAD from AppImage
    kdePackages.kate
    git
    wget
    dua
    htop
    dig
    eza
    pwgen
    helix
    vim
    openssl
    lsd
    bat
    zip
    unzip
    cifs-utils
    superfile
    pv
    iperf3
    bazaar
  ];

  # Enable and configure VSCode.
  programs.vscode = {
    enable = true;
    # extensions = (with pkgs.nix-vscode-extensions.open-vsx; [
    #   janisdd.vscode-edit-csv
    # ]) ++ (with pkgs.nix-vscode-extensions.vscode-marketplace; [
    #   dracula-theme.theme-dracula
    #   yzhang.markdown-all-in-one
    #   catppuccin.catppuccin-vsc
    #   esbenp.prettier-vscode
    #   redhat.vscode-yaml
    #   golang.go
    #   jnoortheen.nix-ide
    #   mechatroner.rainbow-csv
    #   docker.docker
    # ]);
  };

  ### Enable TMUX ###
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  ### FIREWALL ###
  networking.firewall = {
    enable = true;
    allowPing = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable AppImage support.
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  ### STORAGE OPTIMIZATION ###
  # Enable auto-optimisation of the Nix store
  nix.optimise = {
    automatic = true;
    dates = [ "05:00" ];
  };

  ### GARBAGE COLLECTION AUTOMATION ###
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  ### AUTOMATIC SYSTEM UPGRADES ###
  # Pulls the latest config straight from GitHub every hour.
  system.autoUpgrade = {
    enable = true;
    flake = "github:codyjamestechnical/KM-Laptops-Nix#${config.networking.hostName}";
    dates = "hourly";
    randomizedDelaySec = "10min";
    allowReboot = false;
  };

  # Run a missed upgrade on next boot if the laptop was off when the timer fired.
  systemd.timers.nixos-upgrade.timerConfig.Persistent = true;

  ### CLEANUP TMP ON BOOT ###
  boot.tmp.cleanOnBoot = true;

  ### NIX SETTINGS ###
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

}
