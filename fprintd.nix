{ pkgs, ... }:

let
  fpcbep = pkgs.fetchzip {
    url = "https://download.lenovo.com/pccbbs/mobiles/r1slm01w.zip";
    hash = "sha256-/buXlp/WwL16dsdgrmNRxyudmdo9m1HWX0eeaARbI3Q=";
    stripRoot = false;
  };

  overlay = final: prev: {
    libfprint = prev.libfprint.overrideAttrs (attrs: {
      doCheck = false;
      checkPhase = ":";

      configurePhase = ''
        runHook preConfigure
        meson setup build --prefix=$out --buildtype=release \
          --libdir=lib \
          -Dudev_rules_dir=$out/lib/udev/rules.d \
          -Dudev_hwdb_dir=$out/lib/udev/hwdb.d
        runHook postConfigure
      '';

      buildPhase = ''
        runHook preBuild
        ninja -C build
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        ninja -C build install
        runHook postInstall
      '';

      patches = (attrs.patches or []) ++ [ ./fpcmoh.patch ];
      postPatch = (attrs.postPatch or "") + ''
        substituteInPlace meson.build \
          --replace-fail "find_library('fpcbep', required: true)" "find_library('fpcbep', required: true, dirs: '$out/lib')"
      '';
      preConfigure = (attrs.preConfigure or "") + ''
        install -D "${fpcbep}/FPC_driver_linux_27.26.23.39/install_fpc/libfpcbep.so" "$out/lib/libfpcbep.so"
      '';
      postInstall = (attrs.postInstall or "") + ''
        install -Dm644 "${fpcbep}/FPC_driver_linux_libfprint/install_libfprint/lib/udev/rules.d/60-libfprint-2-device-fpc.rules" "$out/lib/udev/rules.d/60-libfprint-2-device-fpc.rules"
        substituteInPlace "$out/lib/udev/rules.d/70-libfprint-2.rules" --replace-fail "/bin/sh" "${pkgs.runtimeShell}"
      '';
    });

    fprintd = prev.fprintd.overrideAttrs (attrs: {
      doCheck = false;
      nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ attrs.nativeCheckInputs;
    });
  };

in
{
  nixpkgs.overlays = [overlay];

  services = {
    fprintd = {
      enable = true;
      package = pkgs.fprintd;
      tod.enable = false;
    };
    udev.packages = [ pkgs.libfprint ];
  };

  security.pam.services = {
    su.fprintAuth = true;
    google-chrome.fprintAuth = true;
    Bitwarden.fprintAuth = true;
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    polkit.fprintAuth = true;
    sshd.fprintAuth = true;
    hyprlock.fprintAuth = true;
  };
}
