# Build one MCP server derivation per server.py under this directory.
# Each is exposed as `bin/mcp-<name>` and is referenced from
# common/ms-researcher.nix via agent.mcps = [ "pubmed" "searxng" "crossref" ].
{ pkgs }:

let
  mkServer = name: pkgs.writers.writePython3Bin "mcp-${name}" {
    libraries = with pkgs.python3Packages; [ httpx ];
    flakeIgnore = [
      "E501"  # long lines — JSON payloads are wide.
      "E402"  # module-level imports below `from __future__`.
      "W503"  # line break before binary operator — black-style.
    ];
  } (builtins.readFile (./. + "/${name}/server.py"));
in
{
  pubmed   = mkServer "pubmed";
  searxng  = mkServer "searxng";
  crossref = mkServer "crossref";
}
