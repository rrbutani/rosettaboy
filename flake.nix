{
  description = "rosettaboy";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
    crane = {
      url = github:ipetkov/crane;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay = {
      url = github:mitchellh/zig-overlay;
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self, nixpkgs, flake-utils, crane, zig-overlay
  }: flake-utils.lib.eachDefaultSystem (system: let

    #################
    # !!! Options !!!
    #################
    enableLto = true;
    enableNativeBuild = true;

    #################

    np = nixpkgs.legacyPackages.${system};
    stdenv = if np.targetPlatform.isAarch64 && np.targetPlatform.isMacOS then
      # We need a newer LLVM than what's currently in the stdenv (LLVM 11) to
      # use `-mcpu=apple-m1`.
      np.llvmPackages_14.libcxxStdenv
    else
      np.stdenv;
    lib = np.lib;

    submodules = with lib; pipe (readFile ./.gitmodules) [
      (splitString "[submodule")
      (filter (x: x != ""))
      (map (splitString "\n"))
      (map (lines: let
        key = pipe (head lines) [
          (replaceStrings [ " " "]" ] [ "" "" ])
          (removePrefix "\"")
          (removeSuffix "\"")
        ];

        values = pipe (tail lines) [
          (filter (x: x != ""))
          (map (x: pipe x [
            (removePrefix "\t")
            (splitString " = ")
            (parts: {
              name = assert (length parts) == 2; elemAt parts 0;
              value = pipe (elemAt parts 1) [
                (removePrefix "\"")
                (removeSuffix "\"")
              ];
            })
          ]))
          (listToAttrs)
        ];
      in { name = key; value = values; }))
      (listToAttrs)
    ];

    craneLib = (crane.lib.${system}).overrideScope' (f: p: { inherit stdenv; });

    # `-march=native` does not yet work on apple silicon; this is a bad
    # workaround...
    #
    # See: https://discourse.llvm.org/t/why-does-march-native-not-work-on-apple-m1/2733/7
    nativeTarget = let t = np.targetPlatform; in
      if t.isMacOS && t.isAarch64
        then "apple-m1" # "apple-latest"
        else "native";

    common = name: {
      src = np.nix-gitignore.gitignoreSource [] ./${name};
      # TODO: file issue about ^ saying that it'll error if the string (empty) is not an absolute path already...

      pname = "rosettaboy-${name}";
      version = "0.0.0";

      # Just checks that we can run the binary:
      installCheckPhase = ''
        $out/bin/$pname --help
      '';
      doInstallCheck = true;
    } // (lib.optionalAttrs enableNativeBuild {
      # If using `-march=native` and equivalents, do not substitute these
      # derivations and do not build remotely.
      allowSubstitutes = false;
      preferLocalBuild = true;

      NIX_CFLAGS_COMPILE = " -mcpu=${nativeTarget} -mcpu=${nativeTarget}";

      NIX_ENFORCE_NO_NATIVE = false;
    });

    # Need a modern LLD version for use on macOS:
    lld = np.llvmPackages_14.lld;
    needsLldDep = enableLto && np.targetPlatform.isMacOS
      && (stdenv.cc.isClang or false);

    packages = {
      cpp = stdenv.mkDerivation ((common "cpp") // {
        nativeBuildInputs = with np; [ cmake ninja pkg-config ]
          ++ (lib.optional needsLldDep lld);
        buildInputs = with np; [ SDL2 ];
        cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ]
          ++ (lib.optional enableLto "-DENABLE_LTO=ON")
          ++ (lib.optional needsLldDep "-DCMAKE_EXE_LINKER_FLAGS:STRING=-fuse-ld=lld")
        ;
        installPhase = ''
          runHook preInstall
          install -D $pname $out/bin/$pname
          runHook postInstall
        '';
      });

      # TODO: native build? the c deps pick this up already
      go = let
        postConfigure = ''
          export GOCACHE="$TMPDIR/_go-cache"
          export GOPATH="$TMPDIR/_go"
        '';
      in (np.buildGoModule.override { inherit stdenv; }) ((common "go") // {
        # The source cannot be named go, unfortunately:
        #
        # TODO: link to issue
        overrideModAttrs = _: { inherit postConfigure; };
        inherit postConfigure;

        vendorHash = "sha256-IjDe0nFtaVWyUUA313pZb6bSCgbrPd4cvZO0G9hs9E4=";
        nativeBuildInputs = with np; [ pkg-config ];
        buildInputs = with np; [ SDL2 ];
        postInstall = "mv $out/bin/src $out/bin/rosettaboy-go";
      });

      # TODO: LTO?
      # nim = null;

      # php = null; # `doInstallCheck = false`; help not implemented
      # py = null;

      rs = let
        common' = common "rs";
        commonArgs = {
          inherit (common') src;
          nativeBuildInputs = with np; [ pkg-config ];
          buildInputs = with np; [ SDL2 ]
            ++ (lib.optional np.targetPlatform.isMacOS np.libiconv)
          ;

          CARGO_PROFILE = if enableLto then "release-lto" else "release";
          RUSTFLAGS = if enableNativeBuild then "-Ctarget-cpu=${nativeTarget}" else "";
        };

        deps = craneLib.buildDepsOnly (commonArgs // {
          pname = "rosettaboy-rs-deps";
        });
      in craneLib.buildPackage (common' // commonArgs // {
        cargoArtifacts = deps;
      });

      # Flakes don't include submodules by default; for ease of use we have
      # nix fetch the submodules for us:
      zig = let
        sdl = with submodules."zig/lib/sdl"; np.fetchgit {
          inherit url;
          rev = branch;
          branchName = branch;
          hash = "sha256-e4fNkVs6jsJJHNbBomdgtWR7+CLK1G6YxnkIgaMvvBo=";
        };
        clap = with submodules."zig/lib/clap"; np.fetchgit {
          inherit url;
          rev = branch;
          branchName = branch;
          hash = "sha256-wZaeOlEEzgFqHCtW9ztiu+HczRltL0geb0fHv1nrgpQ=";
        };
      in np.stdenvNoCC.mkDerivation ((common "zig") // {
        nativeBuildInputs = with np; [
          zig-overlay.packages.${system}.master-2022-10-17
          pkg-config
        ];
        buildInputs = with np; [ SDL2 ]
          ++ lib.optionals np.targetPlatform.isMacOS (
            with np.darwin.apple_sdk.frameworks; [
              np.libiconv
              CoreHaptics AudioToolbox QuartzCore Carbon Metal Cocoa
              ForceFeedback IOKit GameController CoreAudio
            ]
          )
        ;
        preBuild = ''
          export HOME=$TMPDIR

          ln -s ${sdl} lib/sdl
          ln -s ${clap} lib/clap
        '';
        buildPhase = ''
          runHook preBuild

          # not using `stage1` results in segfaults right now...
          zig build \
            -fstage1 \
            --verbose \
            -Dcpu=${if enableNativeBuild then (lib.replaceStrings ["-"] ["_"] nativeTarget) else "baseline"} \
            -Drelease-fast=true
            # ${if enableLto then "-flto" else "-fno-lto"} \

          runHook postBuild
        '';
      });
    };

    opus5 = np.fetchurl {
      url = "https://github.com/sjl/cl-gameboy/blob/master/roms/opus5.gb?raw=true";
      hash = "sha256-6/AoZ3NjBPGQTcE/9vveEaG8CKXbN6b4RTCo90ZTkds=";
    };

    # Using the short args here to accomodate the PHP impl:
    apps = let
      base = builtins.mapAttrs
        (n: pkg: { type = "app"; program = np.lib.getExe pkg; }) packages;
      bench = np.lib.mapAttrs'
        (n: pkg: {
          name = "${n}-bench";
          value = let
            script = np.writeScriptBin "${pkg.pname}-run" ''
              ${np.lib.getExe pkg} -S -H -p 600 -t ${opus5}
            '';
          in { type = "app"; program = np.lib.getExe script; };
        }) packages;
    in base // bench;

    # TODO: switch to running all the CPU tests!
    # TODO: lints / format check
    checks = builtins.mapAttrs
      (n: pkg: np.runCommand "${pkg.pname}-check" { } ''
        ${np.lib.getExe pkg} -S -H -p 600 -t ${opus5} > $out
      '')
      packages;

    packages' = packages // { inherit opus5; };
  in {
    inherit apps checks;
    packages = packages';
    devShells.default = np.mkShell {
      name = "rosettaboy";
      inputsFrom = builtins.attrValues packages;

      # TODO: add `format` deps
      # TODO: add editor deps? + rnix-lsp
      shellHook = ''
        format() { :; } # TODO
      '';
    };
  });
}

# note that we _can_ add format checks, have this replace `blhargg.py` and CI, etc. but didn't do this in this initial PR
