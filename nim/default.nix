{ lib
, stdenvNoCC
, gitignoreSource
, llvmPackages_14
, nimPackages
, nim-argparse
, git
, cacert
, debugSupport ? false
, speedSupport ? false
}:

let
  inherit (nimPackages) buildNimPackage;

  argparse = buildNimPackage rec {
    pname = "argparse";
    version = "master";
    src = nim-argparse;
  };

  # Upstream `nimPackages.sdl2` is marked broken on macOS but it actually works
  # fine:
  sdl2 = nimPackages.sdl2.overrideAttrs (o: {
    meta = o.meta // {
      platforms = o.meta.platforms ++ lib.platforms.darwin;
    };
  });
in

buildNimPackage rec {
  name = "rosettaboy-nim";
  src = gitignoreSource ./.;

  passthru.devTools = [ nimPackages.nim git cacert ];

  nimBinOnly = true;

  nimFlags = []
    ++ lib.optional debugSupport "-d:debug"
    ++ lib.optional (!debugSupport) "-d:release"
    ++ lib.optional (!speedSupport) "-d:nimDebugDlOpen"
    ++ lib.optionals speedSupport [ "-d:danger" "--opt:speed" "-d:lto" "--mm:arc" "--panics:on" ]
    ;

  buildInputs = [ argparse sdl2 ];

  # Wants `lld` on macOS:
  nativeBuildInputs = lib.optional stdenvNoCC.isDarwin llvmPackages_14.bintools;

  postInstall = ''
    mv $out/bin/rosettaboy $out/bin/rosettaboy-nim
  '';

  meta.description = name;
}