{
  runCommandLocal,
  yq-go,
}:
# toYAML ::
#   value -> a
value: let
  yamlOut =
    runCommandLocal "to-yaml"
    {
      nativeBuildInputs = [yq-go];
      value = builtins.toJSON value;
      passAsFile = ["value"];
    }
    ''
      yq -P -o=yaml "$valuePath" > "$out"
    '';
in
  builtins.readFile yamlOut
