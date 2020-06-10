{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  name = "verilog-stuff";
  nativeBuildInputs = [
    verilator symbiyosys yosys z3
    cmake ninja
  ];
  buildInputs = [ zlib boost ];
}
