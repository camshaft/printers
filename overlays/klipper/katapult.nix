# Katapult bootloader overlay
#
# Provides Katapult bootloader package and flashing scripts for MCU updates.
{ katapult }:
final: prev: {
  #####################################################################
  #   Katapult - Bootloader for MCU firmware updates
  #####################################################################

  katapult = final.stdenv.mkDerivation {
    pname = "katapult";
    version = "unstable";
    src = katapult;

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/lib/katapult
      cp -r . $out/lib/katapult/
    '';

    passthru.src = katapult;
  };

  #####################################################################
  #   Katapult Scripts with Python Dependencies
  #####################################################################

  katapult-scripts =
    let
      pythonEnv = final.python3.withPackages (ps: [
        ps.pyserial
        ps.python-can
        ps.packaging
        ps.intelhex
      ]);
    in
    final.stdenv.mkDerivation {
      pname = "katapult-scripts";
      version = "unstable";
      dontUnpack = true;
      buildInputs = [ final.makeWrapper ];

      installPhase = ''
        mkdir -p $out/bin

        # flashtool.py - Main flashing utility
        makeWrapper ${pythonEnv}/bin/python3 $out/bin/katapult-flash \
          --add-flags "${final.katapult}/lib/katapult/scripts/flashtool.py"

        # flash_can.py - CAN bus flashing
        makeWrapper ${pythonEnv}/bin/python3 $out/bin/katapult-flash-can \
          --add-flags "${final.katapult}/lib/katapult/scripts/flash_can.py"

        # flash_usb.py - USB/serial flashing  
        makeWrapper ${pythonEnv}/bin/python3 $out/bin/katapult-flash-usb \
          --add-flags "${final.katapult}/lib/katapult/scripts/flashtool.py" \
          --add-flags "-d"
      '';
    };
}
