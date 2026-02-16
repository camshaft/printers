{ camera-streamer, magic-enum }:
final: prev: {
  camera-streamer = prev.stdenv.mkDerivation rec {
    pname = "camera-streamer";
    version = "0.4.0";

    src = camera-streamer;

    # Patch Makefile for Nix compatibility:
    # - Disable -Werror for newer GCC versions
    # - Use system live555/libdatachannel (no pkg-config in nixpkgs)
    # - Remove submodule build rules
    patches = [
      ../patches/camera-streamer/001-nix-compat.patch
      ../patches/camera-streamer/002-fix-format-specifier.patch
    ];

    nativeBuildInputs = with prev; [
      cmake
      pkg-config
      xxd
    ];

    buildInputs = with prev; [
      ffmpeg
      v4l-utils
      openssl
      live555
      libdatachannel  # System libdatachannel from nixpkgs
      libdatachannel.dev  # System libdatachannel from nixpkgs
      nlohmann_json   # Required for webrtc JSON handling
    ];

    # camera-streamer uses make, not cmake directly
    dontUseCmakeConfigure = true;

    # Link magic_enum submodule from flake input
    postPatch = ''
      rm -rf third_party/magic_enum
      ln -s ${magic-enum} third_party/magic_enum
    '';

    buildPhase = ''
      runHook preBuild
      make USE_LIBCAMERA=0 USE_RTSP=1 USE_LIBDATACHANNEL=1
      runHook postBuild
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp camera-streamer $out/bin/
    '';

    meta = with prev.lib; {
      description = "High-performance low-latency camera streamer for Raspberry Pi";
      homepage = "https://github.com/ayufan/camera-streamer";
      license = licenses.gpl3;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
}
