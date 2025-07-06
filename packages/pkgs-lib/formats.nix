{
  runCommandLocal,
  yq-go,
}: {
  yaml = {
    from =
      # yaml.from ::
      #   path -> a
      #   -- | The nixified version of the input YAML file.
      path: let
        jsonOutputDrv =
          runCommandLocal "from-yaml" {
            nativeBuildInputs = [yq-go];
          }
          ''
            yq -o=json '.' "${path}" > "$out"
          '';
      in
        builtins.fromJSON (builtins.readFile jsonOutputDrv);

    to =
      # yaml.to ::
      #   value -> a
      value: let
        yamlOut =
          runCommandLocal "to-yaml" {
            nativeBuildInputs = [yq-go];
            value = builtins.toJSON value;
            passAsFile = ["value"];
          }
          ''
            yq -P -o=yaml "$valuePath" > "$out"
          '';
      in
        builtins.readFile yamlOut;
  };
}
