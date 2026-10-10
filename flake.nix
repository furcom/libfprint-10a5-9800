{
  description = "NixOS module, overlay and package for libfprint 10a5:9800 support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      overlays.default = final: prev:
        let
          fpcbep = final.fetchzip {
            url = "https://download.lenovo.com/pccbbs/mobiles/r1slm01w.zip";
            hash = "sha256-/buXlp/WwL16dsdgrmNRxyudmdo9m1HWX0eeaARbI3Q=";
            stripRoot = false;
          };
        in {
          libfprint-10a5-9800 = prev.libfprint.overrideAttrs (attrs: {
            doCheck = false;
            checkPhase = ":";
            configurePhase = ''
              runHook preConfigure
              meson setup build --prefix=$out --buildtype=release --libdir=lib -Dudev_rules_dir=$out/lib/udev/rules.d -Dudev_hwdb_dir=$out/lib/udev/hwdb.d
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
              substituteInPlace meson.build --replace-fail "find_library('fpcbep', required: true)" "find_library('fpcbep', required: true, dirs: '$out/lib')"
            '';
            preConfigure = (attrs.preConfigure or "") + ''
              install -D "${fpcbep}/FPC_driver_linux_27.26.23.39/install_fpc/libfpcbep.so" "$out/lib/libfpcbep.so"
            '';
            postInstall = (attrs.postInstall or "") + ''
              install -Dm644 "${fpcbep}/FPC_driver_linux_libfprint/install_libfprint/lib/udev/rules.d/60-libfprint-2-device-fpc.rules" "$out/lib/udev/rules.d/60-libfprint-2-device-fpc.rules"
              substituteInPlace "$out/lib/udev/rules.d/70-libfprint-2.rules" --replace-fail "/bin/sh" "${final.runtimeShell}"
            '';
          });

          fprintd-10a5-9800 = prev.fprintd.overrideAttrs (attrs: {
            doCheck = false;
            nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ attrs.nativeCheckInputs;
          });
        };

      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
        in {
          default = pkgs.libfprint-10a5-9800;
          libfprint-10a5-9800 = pkgs.libfprint-10a5-9800;
          fprintd-10a5-9800 = pkgs.fprintd-10a5-9800;
        }
      );

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.libfprint-10a5-9800;
        in {
          options.services.libfprint-10a5-9800.enable = lib.mkEnableOption "libfprint support for 10a5:9800";

          config = lib.mkIf cfg.enable {
            nixpkgs.overlays = [ self.overlays.default ];
            services = {
              fprintd = {
                enable = true;
                package = pkgs.fprintd-10a5-9800;
                tod.enable = false;
              };
              udev.packages = [ pkgs.libfprint-10a5-9800 ];
            };
          };
        };
    };
}
