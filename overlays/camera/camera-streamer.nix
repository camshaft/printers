final: prev: {
  camera-streamer = prev.stdenv.mkDerivation rec {
    pname = "camera-streamer";
    version = "0.4.0";

    src = prev.fetchFromGitHub {
      owner = "ayufan";
      repo = "camera-streamer";
      rev = "v${version}";
      sha256 = prev.lib.fakeSha256;
      fetchSubmodules = true;
    };

    nativeBuildInputs = with prev; [
      cmake
      pkg-config
      xxd
    ];

    buildInputs = with prev; [
      libcamera
      ffmpeg
      v4l-utils
      openssl
      live555
    ];

    # camera-streamer uses make, not cmake directly
    dontUseCmakeConfigure = true;

    buildPhase = ''
      make
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
