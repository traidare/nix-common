{lib, ...}: rec {
  # Converts a directory to an attrset mapping filenames (without .nix suffix) to their paths
  dirToAttrs = dir:
    lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (
      builtins.readDir dir
    );

  # Like dirToAttrs, but adds a 'default' entry that imports all other modules
  dirToAttrsWithDefault = dir: let
    modules = dirToAttrs dir;
    default = {
      imports = builtins.attrValues (
        # Exclude any existing 'default' to avoid circular imports
        removeAttrs modules ["default"]
      );
    };
  in
    modules // {inherit default;};

  # Recursively converts a directory of NixOS modules into a nested attribute set.
  # Each .nix file becomes a leaf attribute (its path).
  # Each subdirectory becomes a functor attribute set that can be used directly as
  # a NixOS module (importing all children via __functor), while also exposing each
  # child as a named attribute for selective imports.
  #
  # Example: given this directory tree:
  #   nixos-modules/
  #     some_name/
  #       some_module_0.nix
  #       some_module_1.nix
  #     some_other_module.nix
  #
  # recursiveDirToModules ./nixos-modules yields:
  #   {
  #     default = { imports = [ <some_name functor> ./some_other_module.nix ]; };
  #     some_other_module = ./some_other_module.nix;
  #     some_name = <functor>{
  #       some_module_0 = ./some_module_0.nix;
  #       some_module_1 = ./some_module_1.nix;
  #     };
  #   }
  #
  # Usage:
  #   imports = [ nixosModules.some_name ];              # imports both modules
  #   imports = [ nixosModules.some_name.some_module_0 ]; # imports only one
  #
  # The functor works because builtins.isFunction returns true for attrsets with
  # __functor, so the NixOS module system treats them as function modules.
  #
  # Note: avoid placing default.nix or __functor.nix inside module directories,
  # as these names conflict with synthesized attributes.
  recursiveDirToModules = dir: let
    entries = builtins.readDir dir;

    processEntry = name: type: let
      path = dir + "/${name}";
      attrName = lib.removeSuffix ".nix" name;
    in
      if type == "directory"
      then {
        name = attrName;
        value = let
          children = recursiveDirToModules path;
          childrenExposed = removeAttrs children ["default"];
          childImports = builtins.attrValues childrenExposed;
        in
          {__functor = _self: _args: {imports = childImports;};} // childrenExposed;
      }
      else if lib.hasSuffix ".nix" name
      then {
        name = attrName;
        value = path;
      }
      else null;

    processed = lib.filter (x: x != null) (lib.mapAttrsToList processEntry entries);
    modules = lib.listToAttrs processed;

    default = {
      imports = builtins.attrValues (removeAttrs modules ["default"]);
    };
  in
    modules // {inherit default;};

  # Creates a nullable option with a default of null
  mkNullOption = type: description:
    lib.mkOption {
      type = lib.types.nullOr type;
      default = null;
      inherit description;
    };

  # Converts a path to a name by stripping the leading '/' and replacing '/' with '-'
  mkNameFromPath = path:
    builtins.replaceStrings ["/"] ["-"] (lib.removePrefix "/" path);

  # Escape as required by: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
  escapeUnitName = name:
    lib.concatMapStrings (s:
      if lib.isList s
      then "-"
      else s) (
      builtins.split "[^a-zA-Z0-9_.\\-]+" name
    );

  packaging = import ./packaging.nix {inherit lib;};
}
