{ lib
, python311
, gitignoreSource
, fetchFromGitHub
, mypycSupport ? false
}:

let
  py = python311;

  # We use `match` which is only supported in `mypy` v1 and newer:
  # https://github.com/python/mypy/commit/d5e96e381f72ad3fafaae8707b688b3da320587d
  #
  # This hasn't made it's way into `nixpkgs` yet so we override for now:
  # (!!! remove once nixpkgs has 1.0.0+)
  mypy' = py.pkgs.mypy.overridePythonAttrs (old: rec {
    version = "1.0.0";
    buildInputs = (old.buildInputs or []) ++ (with py.pkgs; [ psutil types-psutil ]);
    src = fetchFromGitHub {
      owner = "python";
      repo = "mypy";
      rev = "refs/tags/v${version}";
      hash = "sha256-/E2O6J+o0OiY2v/ogatygaB07D/Z5ZQ6mB0daEQqo+4=";
    };
  });

  runtimeDeps = pyPkgs: with pyPkgs; [ setuptools pysdl2 ];
  devDeps = pyPkgs: with pyPkgs; [ mypy' black ];
in

py.pkgs.buildPythonApplication rec {
  name = "rosettaboy-py";
  src = gitignoreSource ./.;

  nativeBuildInputs = lib.optional mypycSupport mypy';

  passthru = rec {
    python = py.withPackages (p: (runtimeDeps p) ++ (devDeps p));
    devTools = [ python ];
  };

  propagatedBuildInputs = runtimeDeps py.pkgs;

  ROSETTABOY_USE_MYPYC = mypycSupport;
  dontUseSetuptoolsCheck = true;

  meta.description = name;
}
