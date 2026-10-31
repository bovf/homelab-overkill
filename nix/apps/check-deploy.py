#!/usr/bin/env python3
"""Test deploy argument forwarding with fake rebuild/install/SSH executables only."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPR = r"""
let
  f = builtins.getFlake (toString ./.);
  system = builtins.currentSystem;
  pkgs = f.inputs.nixpkgs.legacyPackages.${system};
  recorder = pkgs.writeShellScriptBin "nixos-rebuild" ''
    printf '%s\0' "$@" > "$DEPLOY_TEST_LOG"
  '';
  installer = pkgs.writeShellScriptBin "nixos-anywhere" ''
    printf '%s\0' install "$@" > "$DEPLOY_TEST_LOG"
  '';
  module = import ./nix/apps/deploy.nix {
    nixpkgs = {
      inherit (f.inputs.nixpkgs) lib;
      legacyPackages.${system} = pkgs // { nixos-rebuild-ng = recorder; };
    };
    nixos-anywhere.packages.${system}.default = installer;
  };
  app = module.mkDeployApp system {
  engineer = {
    localTarget = true; remoteTarget = true;
    deploy = { useSudo = true; requireConfirmation = false; };
  };
  pangolin = {
    localTarget = false; remoteTarget = true;
    deploy = { useSudo = false; requireConfirmation = false; };
  };
  };
in (pkgs.writeShellScriptBin "deploy-test" ''
  exec ${app.program} "$@"
'') // { testProgram = app.program; }
"""
FLAGS = ["--offline", "--no-write-lock-file", "--impure"]
result = subprocess.run(["nix", "run", *FLAGS, "--expr", EXPR, "", "--", "help"], cwd=ROOT, capture_output=True, check=False)
assert result.returncode == 0, result.stderr.decode()
app = subprocess.check_output(["nix", "eval", *FLAGS, "--raw", "--expr", f"({EXPR}).testProgram"], cwd=ROOT, text=True).strip()
with tempfile.TemporaryDirectory(prefix="deploy-args-test-") as tmp:
    scratch = Path(tmp)
    log = scratch / "arguments"
    (scratch / "ssh").write_text('#!/usr/bin/env bash\nprintf "unexpected SSH" > "$DEPLOY_TEST_LOG"\nexit 97\n')
    (scratch / "ssh").chmod(0o700)
    env = {k: v for k, v in os.environ.items() if not k.startswith("BASH_FUNC_")}
    env.update(DEPLOY_TEST_LOG=str(log), PATH=str(scratch) + os.pathsep + env["PATH"])
    for action in ("update", "switch", "test"):
        for target in ("engineer-local", "engineer-remote", "pangolin-remote"):
            for low_cost in (False, True):
                log.unlink(missing_ok=True)
                args = [action, target] + (["--low-cost"] if low_cost else [])
                subprocess.run([app, *args], env=env, cwd=ROOT, capture_output=True, check=True)
                actual = log.read_bytes().rstrip(b"\0").decode().split("\0")
                node = target.rsplit("-", 1)[0]
                expected = [
                    "test" if action == "test" else "switch", "--flake", ".#" + node,
                    "--target-host", target, "--build-host", target, "--impure",
                ]
                if node == "engineer":
                    expected += ["--sudo", "--ask-sudo-password"]
                if low_cost:
                    expected += ["--max-jobs", "1", "--cores", "1"]
                assert actual == expected, json.dumps({"actual": actual, "expected": expected})
    for args in (
        ["update"], ["update", "not-a-node", "--low-cost"],
        ["update", "pangolin-remote", "--low-cost", "--low-cost"],
        ["update", "pangolin-remote", "--lowcost"],
        ["update", "pangolin-remote", "--cores", "3"],
        ["status", "pangolin-remote", "--low-cost"],
        ["install", "pangolin-remote", "--low-cost"],
    ):
        log.unlink(missing_ok=True)
        result = subprocess.run([app, *args], env=env, cwd=ROOT, capture_output=True, check=False)
        assert result.returncode != 0 and not log.exists(), args
    log.unlink(missing_ok=True)
    help_text = subprocess.check_output([app, "help"], env=env, cwd=ROOT, text=True)
    assert "--low-cost" in help_text and not log.exists()
print("PASS: default/low-cost update, switch and test forwarding; invalid options never invoke rebuild, SSH or install.")
