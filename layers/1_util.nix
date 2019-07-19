/*
{ pkgs, idris-no-deps, overrides ? (self: super: {}) }: let
  inherit (pkgs.lib) callPackageWith fix' extends;

  Taken from haskell-modules/default.nix, should probably abstract this away
  callPackageWithScope = scope: drv: args: (callPackageWith scope drv args) // {
    overrideScope = f: callPackageWithScope (mkScope (fix' (extends f scope.__unfix__))) drv args;
  };

  mkScope = scope : pkgs // pkgs.xorg // pkgs.gnome2 // scope;

    inherit callPackage;
    inherit idris-no-deps;
*/
self: super: {
  wrapHook = phaseName: phase: "runHook pre${phaseName}\n${phase}\npost${phaseName}"

  util = { #TODO unfuck these
    # Utilities for building packages

    with-packages = self.callPackage ../lib/with-packages.nix {};

    build-builtin-package = import ../lib/build-builtin-package.nix;

    };
  }
