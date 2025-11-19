{
  age,
  inputs',
  writeShellApplication,
}:
writeShellApplication {
  name = "nixos-deploy";

  runtimeInputs = [
    age
    inputs'.nixos-sops-bootstrap.packages.nixos-sops-bootstrap
    inputs'.nixos-anywhere.packages.nixos-anywhere
  ];

  text = builtins.readFile ./nixos-deploy.sh;
}
