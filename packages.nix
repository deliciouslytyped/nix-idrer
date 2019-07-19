{lib, callPackage}:
let rooted = callPackage ./extern/nix-rootedoverlay/rooted.nix {};
    inherit (rooted.lib) interface overlays;
in
  rooted.mkRoot {
    interface = (self: {
      root = self.idris;
      withPackages = scope: root: selector: self.util.with-packages root (selector scope);
      });
    layers = overlays.autoimport2 ./layers;
    }
