{lib, ...}: rec {
  discover = path: transform:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (name: value: value == "directory"))
      transform
    ];

  discoverWrapperModules = path:
    if path == null
    then []
    else discover path (attrs: map (name: path + "/${name}") (builtins.attrNames attrs));

  discoverPackages = {
    path,
    callPackage,
    extraArgs ? {},
  }:
    discover path (builtins.mapAttrs (name: _: callPackage (path + "/${name}") extraArgs));
}
