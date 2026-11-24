{ lib, appimageTools, fetchurl, }:
let
  pname = "FreeCAD";
  version = "1.1.4";
  pythonVersion = "311";

  src = fetchurl {
    url = "https://github.com/FreeCAD/FreeCAD/releases/download/${version}/FreeCAD_${version}-Linux-x86_64-py${pythonVersion}.AppImage";
    sha256 = "f6dc6ba676e5ac96a565ebc8d657232f94c6158e85b4352141bd1a46f6b43434"; # this needs to be updated when the version changes
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/*.desktop -t $out/share/applications
    install -Dm444 ${appimageContents}/*.png -t $out/share/pixmaps
    substituteInPlace $out/share/applications/*.desktop \
      --replace-warn 'Exec=AppRun' 'Exec=${meta.mainProgram}'
  '';

  meta = {
    description = "3D Parametric Modeler";
    homepage = "https://github.com/FreeCAD/FreeCAD";
    downloadPage = "https://github.com/FreeCAD/FreeCAD/releases";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "freecad";
  };
}
