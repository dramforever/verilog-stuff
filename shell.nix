{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  abseil-cpp-unstable = abseil-cpp.overrideAttrs (old: {
    version = "unstable-2020-06-17";
    src = fetchFromGitHub {
      owner = "abseil";
      repo = "abseil-cpp";
      rev = "4ccc0fce09836a25b474f4b1453146dae2c29f4d";
      sha256 = "0mpby3ar0nsxsbh62559fbqa5qvgywzy70sqlmlxm3bhii9p2gh3";
    };
  });

in mkShell {
  name = "verilog-stuff";
  nativeBuildInputs = [
    verilator symbiyosys yosys z3
    cmake ninja
  ];
  buildInputs = [ zlib abseil-cpp-unstable ];
}
