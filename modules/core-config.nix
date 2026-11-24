{ config, pkgs, inputs, ... }:

let
  # KM-Laser Inkscape extension bundle, exposed to the Inkscape flatpak below.
  km-laser = pkgs.callPackage ../packages/km-laser.nix { src = inputs.km-laser; };
in
{
  imports = [
    ./firefox.nix
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

  # Set default shell to ZSH.
  users.defaultUserShell = pkgs.zsh;

  # ZSH configuration.
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    histSize = 10000;

    autosuggestions.enable = true;
    shellAliases = {
      # Systemctl Service Management
      startsvc = "sudo systemctl start";
      stopsvc = "sudo systemctl stop";
      restartsvc = "sudo systemctl restart";
      logsvc = "sudo journalctl -xeu";

      # File system aliases
      ls = "ls -lA";
      cat = "bat";
      spf = "superfile";

      # Speed Tests
      speed-atlanta = "iperf3 -c atl.speedtest.clouvider.net -p 5200-5209 && ping -U -c 10 atl.speedtest.clouvider.net";
      speed-germany = "iperf3 -c speedtest.fra1.de.leaseweb.net -p 5201-5210 && ping -U -c 10 speedtest.fra1.de.leaseweb.net";
      speed-amsterdam = "iperf3 -c ams.speedtest.clouvider.net -p 5200-5209 && ping -U -c 10 ams.speedtest.clouvider.net";
      speed-canada = "iperf3 -c speedtest.mtl2.ca.leaseweb.net -p 5201-5210 && ping -U -c 10 speedtest.mtl2.ca.leaseweb.net";

      # Rebuild switch NixOS from the latest commit on GitHub
      rebuild = "sudo nixos-rebuild switch --refresh --flake 'github:codyjamestechnical/KM-Laptops-Nix#${config.networking.hostName}'";

    };
  };

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
