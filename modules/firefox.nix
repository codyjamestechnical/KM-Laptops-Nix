{ config, lib, pkgs, ... }:

{

  environment.systemPackages = [
    pkgs.firefox
  ];

  # Enable Firefox
  programs.firefox = {
    enable = true;

    # enable plasma-browser-integration
    nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ];

    preferences = {
      "browser.startup.homepage" = "https://wiki.knoxmakers.org";
      "widget.use-xdg-desktop-portal.file-picker" = 1; # use kde file picker
    };

    policies = {
      # Updates & Background Services
      AppAutoUpdate                 = true;
      BackgroundAppUpdate           = true;

      # Feature Disabling
      DisableBuiltinPDFViewer       = false;
      DisableFirefoxStudies         = true;
      DisableFirefoxAccounts        = true;
      DisableFirefoxScreenshots     = false;
      DisableForgetButton           = false;
      DisableMasterPasswordCreation = true;
      DisableProfileImport          = true;
      DisableProfileRefresh         = false;
      DisableSetDesktopBackground   = false;
      DisablePocket                 = true;
      DisableTelemetry              = true;
      DisableFormHistory            = true;
      DisablePasswordReveal         = true;

      # Access Restrictions
      BlockAboutConfig              = true;
      BlockAboutProfiles            = true;
      BlockAboutSupport             = true;

      # UI and Behavior
      # DisplayMenuBar                = "never";
      DontCheckDefaultBrowser       = true;
      HardwareAcceleration          = true;
      OfferToSaveLogins             = false;
      DefaultDownloadDirectory      = config.xdg.userDirs.download;

      # Extensions
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = let
        moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
      in {
        # Block all extensions by default
        "*".installation_mode = "blocked";

        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url       = moz "uborigin";
          installation_mode = "force_installed";
          updates_disabled  = false;
        };

        # Privacy Badger
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url       = moz "privacy-badger17";
          installation_mode = "force_installed";
          updates_disabled  = false;
        };
      };

      # Extension configuration
      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = {
          userSettings = rec {
            uiTheme            = "dark";
            uiAccentCustom     = true;
            uiAccentCustom0    = "#8300ff";
            cloudStorageEnabled = false;

            importedLists = [
              "https://filters.adtidy.org/extension/ublock/filters/3.txt"
            ];

            externalLists = lib.concatStringsSep "\n" importedLists;
          };

          selectedFilterLists = [
            "CZE-0"
            "adguard-generic"
            "adguard-annoyance"
            "adguard-social"
            "adguard-spyware-url"
            "easylist"
            "easyprivacy"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            "plowe-0"
            "ubabuse"
            "ubbadware"
            "ubfilters"
            "ubprivacy"
            "ubquick-fixes"
            "ubunbreak"
            "urlhaus-1"
          ];
        };
      };
    };



      profiles.default.search = {
        force           = true;
        default         = "ddg";
        privateDefault  = "ddg";

        engines = {
          "Nix Options" = {
            definedAliases = [ "@no" ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            urls = [ { template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}"; } ];
          };
          "Nix Packages" = {
            definedAliases = [ "@np" ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            urls = [ { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; } ];
          };
          "NixOS Wiki" = {
            definedAliases = [ "@nw" ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
          };
        };
      };
  };
}
