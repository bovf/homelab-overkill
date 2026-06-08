{ python3Packages }:

python3Packages.buildPythonApplication {
  pname = "ms-mcp-pubmed";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.mcp python3Packages.httpx ];
  doCheck = false;
}
