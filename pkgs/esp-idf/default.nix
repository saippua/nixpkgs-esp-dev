{ rev ? "v5.3"
, sha256 ? "sha256-w+xyva4t21STVtfYZOXY2xw6sDc2XvJXBZSx+wd1N6Y="
, toolsToInclude ? [
    "xtensa-esp-elf-gdb"
    "riscv32-esp-elf-gdb"
    "xtensa-esp-elf"
    "esp-clang"
    "riscv32-esp-elf"
    "esp32ulp-elf"
    "openocd-esp32"
  ]
, stdenv
, lib
, fetchFromGitHub
, makeWrapper
, callPackage

, python3

  # Tools for using ESP-IDF.
, git
, wget
, gnumake
, flex
, bison
, gperf
, pkg-config
, cmake
, ninja
, ccache
, libusb1
, ncurses5
, dfu-util
}:

let
  src = fetchFromGitHub {
    owner = "espressif";
    repo = "esp-idf";
    rev = "refs/tags/${rev}";
    sha256 = sha256;
    fetchSubmodules = true;
    leaveDotGit = false;
  };

  allTools = callPackage (import ./tools.nix) {
    toolSpecList = (builtins.fromJSON (builtins.readFile "${src}/tools/tools.json")).tools;
    versionSuffix = "esp-idf-${rev}";
  };

  toolDerivationsToInclude = builtins.map (toolName: allTools."${toolName}") toolsToInclude;

  customPython =
    (python3.withPackages
      (pythonPackages:
        let
          customPythonPackages = callPackage (import ./python-packages.nix) { inherit pythonPackages; };
        in
        with pythonPackages;
        with customPythonPackages;
        [
          # This list is from `tools/requirements/requirements.core.txt` in the
          # ESP-IDF checkout.
          setuptools
          click
          pyserial
          cryptography
          pyparsing
          pyelftools
          idf-component-manager
          esp-coredump
          esptool
          esp-idf-kconfig
          esp-idf-monitor
          esp-idf-size
          esp-idf-panic-decoder
          pyclang

          freertos_gdb
          pip

          packaging
          esp-idf-nvs-partition-gen
          construct
        ]));
in
stdenv.mkDerivation rec {
  pname = "esp-idf";
  version = rev;

  inherit src;

  # This is so that downstream derivations will have IDF_PATH set.
  setupHook = ./setup-hook.sh;

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [
    # This is in propagatedBuildInputs so that downstream derivations will run
    # the Python setup hook and get PYTHONPATH set up correctly.
    customPython

    # Tools required to use ESP-IDF.
    git
    wget
    gnumake

    flex
    bison
    gperf
    pkg-config

    cmake
    ninja

    ncurses5
    ccache

    dfu-util
    libusb1
  ] ++ toolDerivationsToInclude;

  # We are including cmake and ninja so that downstream derivations (eg. shells)
  # get them in their environment, but we don't actually want any of their build
  # hooks to run, since we aren't building anything with them right now.
  dontUseCmakeConfigure = true;
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;
  dontUseNinjaCheck = true;

  buildPhase = ''
    mkdir -p $out
    cp -rv . $out/
  '';
  installPhase = ''
    ln -s ${customPython} $out/python-env
    # ln -s ${customPython}/lib $out/lib
 '';
}
