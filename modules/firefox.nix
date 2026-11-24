{ config, lib, pkgs, ... }:

{

  # Enable Firefox (ESR is required for the SearchEngines policy)
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;

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
      DefaultDownloadDirectory      = "\${home}/Downloads";

      # Search engines (note: this policy is only honored by Firefox ESR)
      SearchEngines = {
        Default         = "DuckDuckGo";
        DefaultPrivate  = "DuckDuckGo";
        PreventInstalls = false;

        Add = let
          nixIcon = "file://${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        in [
          {
            Name        = "Nix Options";
            Alias       = "@no";
            IconURL     = nixIcon;
            Method      = "GET";
            URLTemplate = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
          }
          {
            Name        = "Nix Packages";
            Alias       = "@np";
            IconURL     = nixIcon;
            Method      = "GET";
            URLTemplate = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
          }
          {
            Name        = "NixOS Wiki";
            Alias       = "@nw";
            IconURL     = nixIcon;
            Method      = "GET";
            URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
          }
        ];
      };

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
  };
}
