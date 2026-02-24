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
  # Each subdirectory becomes an attribute set that is itself a valid NixOS module
  # (containing `imports = [ ... ]` of all its children), while also exposing each
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
  #     default = { imports = [ <some_name module> ./some_other_module.nix ]; };
  #     some_other_module = ./some_other_module.nix;
  #     some_name = {
  #       imports = [ ./some_module_0.nix ./some_module_1.nix ];
  #       some_module_0 = ./some_module_0.nix;
  #       some_module_1 = ./some_module_1.nix;
  #     };
  #   }
  #
  # Importing `some_name` applies both some_module_0 and some_module_1.
  # Importing `some_name.some_module_0` applies only that single module.
  recursiveDirToModules = dir: let
    entries = builtins.readDir dir;

    # Process a single directory entry into a name-value pair
    processEntry = name: type: let
      path = dir + "/${name}";
      attrName = lib.removeSuffix ".nix" name;
    in
      if type == "directory"
      then {
        name = attrName;
        value = let
          children = recursiveDirToModules path;
          # Collect all importable values: paths for files, the attrset itself for subdirs
          childImports =
            lib.mapAttrsToList (
              _: v:
                if builtins.isPath v
                then v
                else v # subdirectory attrsets are already valid NixOS modules
            ) (removeAttrs children ["default"]);
        in
          {imports = childImports;} // (removeAttrs children ["default"]);
      }
      else if lib.hasSuffix ".nix" name
      then {
        name = attrName;
        value = path;
      }
      else null;

    processed = lib.filter (x: x != null) (lib.mapAttrsToList processEntry entries);
    modules = lib.listToAttrs processed;

    # The top-level default imports everything (directories as modules, files as paths)
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
