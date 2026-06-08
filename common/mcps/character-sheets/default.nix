{ python3Packages }:

python3Packages.buildPythonApplication {
  pname = "koth-mcp-character-sheets";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.mcp ];
  doCheck = false;
}
