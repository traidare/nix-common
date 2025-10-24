final: prev: {
  formats = final.callPackage ./formats.nix {};
  scripts = final.callPackage ./scripts.nix {};
}
