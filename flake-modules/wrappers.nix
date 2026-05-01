# Generate NixOS modules from wrappers
{
  inputs,
  config,
  ...
}: {
  imports = [inputs.nix-wrapper-modules.flakeModules.default];
  flake.nixosWrapperModules = builtins.mapAttrs (_: v: v.install) config.flake.wrappers;
}
