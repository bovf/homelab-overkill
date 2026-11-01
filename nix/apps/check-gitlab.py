#!/usr/bin/env python3
"""Check current GitLab/Redis declarations and synthetic startup; optional local Helm rendering."""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPR = '''
let c = (builtins.getFlake (toString ./. )).nixosConfigurations.engineer.config;
in {
  helm = c.sops.templates."helm/gitlab.yaml".content;
  backupSecret = c.sops.templates."gitlab/backup-storage.yaml".content;
  backupMode = c.sops.templates."gitlab/backup-storage.yaml".mode;
  redis = c.services.k3s.manifests.gitlab-redis.content;
  externalServices = map (name: c.services.k3s.manifests.${name}.content)
    ["gitlab-webservice-extip" "gitlab-registry-extip" "gitlab-shell-extip"];
  publicSso = c.workloads.pangolinResources.gitlab.ssoEnabled;
  kubernetesVersion = c.services.k3s.package.version;
}
'''


def yaml_json(text, expression="."):
    result = subprocess.run(
        ["yq", "eval-all", "-o=json", expression, "-"], input=text,
        text=True, capture_output=True, check=True,
    )
    return json.loads(result.stdout)


def check_startup(source):
    """Run the evaluated command with a fake server, synthetic passwords and disposable data."""
    with tempfile.TemporaryDirectory(prefix="gitlab-redis-test-") as tmp:
        root = Path(tmp)
        data = root / "data"
        data.mkdir()
        sentinel = data / "existing-data"
        sentinel.write_text("keep existing persistence\n")
        auth = root / "redis-auth.conf"
        executable = root / "redis-server"
        executable.write_text("#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$TEST_ARGS\"\n")
        executable.chmod(0o755)
        script = source.replace("/data", str(data)).replace("/tmp/redis-auth.conf", str(auth))
        env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "TEST_ARGS": str(root / "argv")}
        for password in ("", "line\nbreak", "carriage\rreturn", "tab\tvalue"):
            result = subprocess.run(
                ["sh", "-ec", script], env={**env, "REDISCLI_AUTH": password},
                text=True, capture_output=True, check=False,
            )
            assert result.returncode != 0
            assert not auth.exists() and not (root / "argv").exists()
        for password in ("synthetic-password", 'quote"slash\\space $value'):
            result = subprocess.run(
                ["sh", "-ec", script], env={**env, "REDISCLI_AUTH": password},
                text=True, capture_output=True, check=True,
            )
            escaped = password.replace("\\", "\\\\").replace('"', '\\"')
            assert auth.read_text() == f'requirepass "{escaped}"\n'
            assert auth.stat().st_mode & 0o777 == 0o600
            argv = (root / "argv").read_text()
            assert password not in result.stdout + result.stderr + argv
            assert "--appendonly\nyes\n--appendfsync\neverysec" in argv
            assert "--maxmemory-policy\nnoeviction" in argv
            assert sentinel.read_text() == "keep existing persistence\n"


def check_render(chart_dir, chart, values, config):
    metadata = yaml_json((chart_dir / "Chart.yaml").read_text())
    assert metadata["version"] == chart["spec"]["version"]
    # Synthetic hostnames only; no secret decryption or live release lookup.
    values["global"]["hosts"] = {
        "domain": "example.invalid", "gitlab": {"name": "gitlab.example.invalid"},
        "registry": {"name": "registry.example.invalid"},
    }
    with tempfile.TemporaryDirectory(prefix="gitlab-helm-test-") as tmp:
        values_file = Path(tmp) / "values.json"
        values_file.write_text(json.dumps(values))
        rendered = subprocess.check_output([
            "helm", "template", "gitlab", str(chart_dir), "--namespace", "cicd",
            "--is-upgrade", "--kube-version", config["kubernetesVersion"].split("+")[0],
            "-f", str(values_file),
        ], text=True)
    objects = yaml_json(rendered, "[.]")
    assert not any(o["kind"] in ("Gateway", "HTTPRoute", "TCPRoute") for o in objects)
    pods = [o["spec"]["template"] for o in objects if o["kind"] in ("Deployment", "StatefulSet")]
    for service in config["externalServices"]:
        selector = service["spec"]["selector"]
        matching = [pod for pod in pods if selector.items() <= pod["metadata"]["labels"].items()]
        assert matching, service["metadata"]["name"]
        for port in service["spec"]["ports"]:
            assert any(
                port["targetPort"] == container_port["containerPort"]
                for pod in matching for container in pod["spec"]["containers"]
                for container_port in container.get("ports", [])
            ), (service["metadata"]["name"], port)
    assert not any(o["kind"] == "StatefulSet" and o["metadata"]["name"] == "gitlab-redis-master" for o in objects)
    print("GitLab chart rendered; existing backend selectors and ports match.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chart-dir", type=Path, help="Unpacked current GitLab chart, downloaded separately")
    args = parser.parse_args()
    config = json.loads(subprocess.check_output([
        "nix", "eval", "--offline", "--no-write-lock-file", "--impure", "--json", "--expr", EXPR,
    ], cwd=ROOT))
    chart = yaml_json(config["helm"])
    values = yaml_json(chart["spec"]["valuesContent"])
    assert "redis" not in values, "Redis belongs to its own Nix manifest, not the GitLab chart"
    assert values["global"]["redis"] == {
        "host": "gitlab-redis-external.cicd.svc.cluster.local", "port": 6379,
        "auth": {"enabled": True, "secret": "gitlab-redis-secret", "key": "secret"},
    }
    assert values["global"]["gatewayApi"] == {"enabled": False, "installEnvoy": False, "configureCertmanager": False}
    assert values["global"]["ingress"]["enabled"] and values["global"]["ingress"]["class"] == "traefik"
    assert not config["publicSso"], "GitLab OAuth must not be intercepted by Pangolin SSO"
    backup_config = values["gitlab"]["toolbox"]["backups"]["objectStorage"]["config"]
    secret = yaml_json(config["backupSecret"])
    assert backup_config == {"secret": secret["metadata"]["name"], "key": "config"}
    assert config["backupMode"] == "0600"
    pvc, service, deployment = config["redis"]
    assert pvc["metadata"]["name"] == "gitlab-redis-external"
    assert pvc["spec"]["storageClassName"] == "local-path"
    assert service["spec"]["type"] == "ClusterIP" and "externalIPs" not in service["spec"]
    assert deployment["spec"]["replicas"] == 1 and deployment["spec"]["strategy"]["type"] == "Recreate"
    pod = deployment["spec"]["template"]["spec"]
    assert pod["volumes"][0]["persistentVolumeClaim"]["claimName"] == pvc["metadata"]["name"]
    container = pod["containers"][0]
    assert container["command"] == ["/bin/sh", "-ec"] and len(container["args"]) == 1
    assert container["env"][0]["valueFrom"]["secretKeyRef"] == {"name": "gitlab-redis-secret", "key": "secret"}
    assert "@sha256:" in container["image"] and not pod["automountServiceAccountToken"]
    assert pod["containers"][1]["env"][1]["valueFrom"]["secretKeyRef"] == container["env"][0]["valueFrom"]["secretKeyRef"]
    assert service["spec"]["ports"][1]["port"] == 9121
    check_startup(container["args"][0])
    if args.chart_dir:
        check_render(args.chart_dir, chart, values, config)
    print("Current GitLab/Redis configuration and startup checks passed (no live access).")


if __name__ == "__main__":
    main()
