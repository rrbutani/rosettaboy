{ lib
, stdenv
, cmake
, SDL2
, pkg-config
, clang-tools ? null
, ltoSupport ? false
, debugSupport ? false
}:
stdenv.mkDerivation rec {
  name = "rosettaboy-c";

  src = ./.;

  passthru.devTools = [ clang-tools ];

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ cmake pkg-config ];

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;

  meta.description = name;
}
