# KlipperScreen overlay
#
# Touch UI for Klipper printers.
{ klipperscreen }:
final: prev: {
  #####################################################################
  #   KlipperScreen - Touch UI for Klipper
  #####################################################################

  klipperscreen = final.python3Packages.buildPythonApplication {
    pname = "KlipperScreen";
    version = "unstable";
    src = klipperscreen;
    format = "other";

    nativeBuildInputs = with final; [
      wrapGAppsHook3
      gobject-introspection
    ];

    pythonPath = with final.python3Packages; [
      jinja2
      netifaces
      requests
      websocket-client
      pycairo
      pygobject3
      mpv
      six
      dbus-python
      sdbus-networkmanager
    ];

    dontWrapGApps = true;

    preFixup = ''
      mkdir -p $out/bin
      cp -r . $out/dist
      gappsWrapperArgs+=(--set PYTHONPATH "$PYTHONPATH")
      wrapGApp $out/dist/screen.py
      ln -s $out/dist/screen.py $out/bin/KlipperScreen
    '';
  };
}
