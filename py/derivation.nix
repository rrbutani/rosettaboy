{
  lib,
  python311,
  gitignoreSource,
  mypycSupport ? false
}:

let
  py = python311;
  runtimeDeps = pyPkgs: with pyPkgs; [ setuptools pysdl2 ];
  devDeps = pyPkgs: with pyPkgs; [ mypy black ];
in

py.pkgs.buildPythonApplication rec {
  name = "rosettaboy-py";
  src = gitignoreSource ./.;

  nativeBuildInputs = lib.optional mypycSupport py.pkgs.mypy;

  passthru = rec {
    python = py.withPackages (p: (runtimeDeps p) ++ (devDeps p));
    devTools = [ python ];
  };

  propagatedBuildInputs = runtimeDeps py.pkgs;

  ROSETTABOY_USE_MYPYC = mypycSupport;

  meta = with lib; {
    inherit name;
    mainProgram = "rosettaboy-py";
  };
}
