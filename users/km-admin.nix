{
  inputs,
  config,
  pkgs,
  ...
}:
{
  users.users."kmadmin" = {
    isNormalUser = true;
    description = "KM Admin";
    extraGroups = [ "networkmanager" "wheel" ];

    # user specific packages to only install for this user
    packages = with pkgs; [
    #  thunderbird
    ];
  };
}
