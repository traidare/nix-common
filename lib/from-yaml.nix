{
  runCommandLocal,
  yq-go,
}:
# fromYAML ::
#   Path -> a
#   -- | The nixified version of the input YAML file.
path: let
  jsonOutputDrv =
    runCommandLocal
    "from-yaml"
    {nativeBuildInputs = [yq-go];}
    "yq -o=json '.' \"${path}\" > \"$out\"";
in
  builtins.fromJSON (builtins.readFile jsonOutputDrv)
