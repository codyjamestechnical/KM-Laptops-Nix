{ lib, stdenvNoCC, src }:

# KM-Laser: Knox Makers' bundle of Inkscape extensions for laser cutting.
# The source is pinned as a flake input (see flake.nix), so no hash is
# needed here; update it with `nix flake update km-laser`.
stdenvNoCC.mkDerivation {
  pname = "km-laser";
  version = src.shortRev or "unstable";

  inherit src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/inkscape/extensions
    cp -r extensions/. $out/share/inkscape/extensions/

    runHook postInstall
  '';

  meta = {
    description = "Bundle of Inkscape extensions useful for laser cutting/engraving";
    homepage = "https://github.com/KnoxMakers/KM-Laser";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
