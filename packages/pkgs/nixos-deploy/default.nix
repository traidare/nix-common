{
  age,
  inputs',
  writeShellApplication,
}:
writeShellApplication {
  name = "nixos-deploy";

  runtimeInputs = [
    age
    inputs'.nix-config-helper.packages.nix-config-helper
    inputs'.nixos-anywhere.packages.nixos-anywhere
  ];

  text = builtins.readFile ./nixos-deploy.sh;
}
