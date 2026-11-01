#!/usr/bin/env python3
"""Offline GitLab upgrade checks. Optional --charts-dir renders downloaded charts; no cluster access."""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "workloads/namespace/cicd/apps/gitlab"
VERSIONS = {
    "9.5.1": "18.5.1",
    "9.5.7": "18.5.7",
    "9.8.12": "18.8.11",
    "9.11.16": "18.11.14",
    "10.2.10": "19.2.10",
    "10.5.4": "19.5.3",
}
EXPR = '''
let
  f = builtins.getFlake (toString ./.);
  base = f.nixosConfigurations.engineer;
  describe = node: let c = node.config; in {
    helm = c.sops.templates."helm/gitlab.yaml".content;
    backupSecret = c.sops.templates."gitlab/backup-storage.yaml".content;
    backupMode = c.sops.templates."gitlab/backup-storage.yaml".mode;
    redis = c.services.k3s.manifests.gitlab-redis.content or [];
    externalServices = map (name: c.services.k3s.manifests.${name}.content)
      ["gitlab-webservice-extip" "gitlab-registry-extip" "gitlab-shell-extip"];
  };
  stage = version: externalRedis: describe (base.extendModules {
    modules = [{ workloads.gitlab = {
      chartVersion = f.inputs.nixpkgs.lib.mkForce version;
      externalRedis = f.inputs.nixpkgs.lib.mkForce externalRedis;
    }; }];
  });
  invalid = base.extendModules {
    modules = [{ workloads.gitlab = {
      chartVersion = f.inputs.nixpkgs.lib.mkForce "10.5.4";
      externalRedis = f.inputs.nixpkgs.lib.mkForce false;
    }; }];
  };
in {
  final = describe base;
  defaultChartVersion = base.options.workloads.gitlab.chartVersion.default;
  stages = [
    (stage "9.5.1" false)
    (stage "9.5.7" false)
    (stage "9.8.12" false)
    (stage "9.11.16" false)
    (stage "9.11.16" true)
    (stage "10.2.10" true)
  ];
  rejectsBundledRedisOnChart10 = !(builtins.tryEval invalid.config.system.build.toplevel.drvPath).success;
  runner = base.config.sops.templates."helm/gitlab-nix-cache-runner.yaml".content;
  postgresJob = base.config.services.k3s.manifests.postgresql-gitlab-init-job.content;
  publicSso = base.config.workloads.pangolinResources.gitlab.ssoEnabled;
  kubernetesVersion = base.config.services.k3s.package.version;
}
'''


def yaml_json(text, expression="."):
    result = subprocess.run(
        ["yq", "eval-all", "-o=json", expression, "-"], input=text,
        text=True, capture_output=True, check=True,
    )
    return json.loads(result.stdout)


def check_startup():
    """Exercise the actual pod command with a fake server and disposable data."""
    source = (APP / "redis-start.sh").read_text()
    with tempfile.TemporaryDirectory(prefix="gitlab-redis-test-") as tmp:
        root = Path(tmp)
        data = root / "data"
        data.mkdir()
        auth = root / "redis-auth.conf"
        marker = data / ".homelab-redis-restored"
        manifest = data / "appendonlydir/appendonly.aof.manifest"
        manifest.parent.mkdir()
        executable = root / "redis-server"
        executable.write_text("#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$TEST_ARGS\"\n")
        executable.chmod(0o755)
        script = source.replace("/data", str(data)).replace("/tmp/redis-auth.conf", str(auth))
        env = {**os.environ, "PATH": f"{root}:{os.environ['PATH']}", "TEST_ARGS": str(root / "argv")}

        def run(password="synthetic-password"):
            return subprocess.run(
                ["sh", "-ec", script], env={**env, "REDISCLI_AUTH": password},
                text=True, capture_output=True, check=False,
            )

        assert run().returncode != 0, "Empty Redis must not start"
        marker.write_text("verified synthetic restore\n")
        assert run().returncode != 0, "A marker alone must not bypass the data check"
        marker.unlink()
        manifest.write_text("synthetic AOF manifest\n")
        assert run().returncode != 0, "Data alone must not bypass restore confirmation"
        marker.write_text("verified synthetic restore\n")
        for bad in ("", "line\nbreak", "carriage\rreturn", "tab\tvalue"):
            result = run(bad)
            assert result.returncode != 0
            assert not auth.exists() and not (root / "argv").exists()
        for password in ("synthetic-password", 'quote"slash\\space $value'):
            result = run(password)
            assert result.returncode == 0, result.stderr
            escaped = password.replace("\\", "\\\\").replace('"', '\\"')
            assert auth.read_text() == f'requirepass "{escaped}"\n'
            assert auth.stat().st_mode & 0o777 == 0o600
            assert password not in result.stdout + result.stderr + (root / "argv").read_text()
            assert "--appendonly\nyes" in (root / "argv").read_text()
            assert "--maxmemory-policy\nnoeviction" in (root / "argv").read_text()


def check_stage(stage, charts_dir, kubernetes_version):
    chart = yaml_json(stage["helm"])
    version = chart["spec"]["version"]
    assert version in VERSIONS
    values = yaml_json(chart["spec"]["valuesContent"])
    external = bool(stage["redis"])
    assert values["redis"]["install"] is not external
    assert values["global"]["redis"]["auth"] == {
        "enabled": True, "secret": "gitlab-redis-secret", "key": "secret",
    }
    assert values["global"]["redis"]["host"] == (
        "gitlab-redis-external.cicd.svc.cluster.local" if external else None
    )
    assert values["global"]["gatewayApi"] == {"enabled": False, "installEnvoy": False, "configureCertmanager": False}
    assert values["global"]["ingress"]["class"] == "traefik"
    assert values["global"]["ingress"]["provider"] == "traefik"
    assert values["global"]["ingress"]["enabled"]
    assert not values["global"]["minio"]["enabled"] and not values["postgresql"]["install"]
    assert values["global"]["psql"]["host"] == "postgresql.database.svc.cluster.local"
    assert values.get("upgradeCheck", {}).get("enabled", True)
    assert values["global"]["appConfig"]["backups"] == {"bucket": "gitlab-backups", "tmpBucket": "gitlab-tmp"}
    backup_config = values["gitlab"]["toolbox"]["backups"]["objectStorage"]["config"]
    secret = yaml_json(stage["backupSecret"])
    assert backup_config == {"secret": secret["metadata"]["name"], "key": "config"}
    assert stage["backupMode"] == "0600"
    assert "host_base = minio.database.svc.cluster.local:9000" in secret["stringData"]["config"]

    if external:
        pvc, service, deployment = stage["redis"]
        assert pvc["kind"] == "PersistentVolumeClaim" and pvc["spec"]["storageClassName"] == "local-path"
        assert pvc["metadata"]["name"] == "gitlab-redis-external"
        assert service["spec"]["type"] == "ClusterIP" and "externalIPs" not in service["spec"]
        assert deployment["spec"]["replicas"] == 1 and deployment["spec"]["strategy"]["type"] == "Recreate"
        pod = deployment["spec"]["template"]["spec"]
        assert pod["volumes"][0]["persistentVolumeClaim"]["claimName"] == pvc["metadata"]["name"]
        assert "redis-data-gitlab-redis-master-0" not in json.dumps(pod), "Never share the old writable PVC"
        container = pod["containers"][0]
        assert container["args"] == [(APP / "redis-start.sh").read_text()]
        assert container["env"][0]["valueFrom"]["secretKeyRef"] == {"name": "gitlab-redis-secret", "key": "secret"}
        assert "7.2.17-bookworm@sha256:" in container["image"]
        assert not pod["automountServiceAccountToken"]
        assert pod["containers"][1]["env"][1]["valueFrom"]["secretKeyRef"] == container["env"][0]["valueFrom"]["secretKeyRef"]
        assert service["spec"]["ports"][1]["port"] == 9121

    if charts_dir:
        chart_dir = charts_dir / version / "gitlab"
        metadata = yaml_json((chart_dir / "Chart.yaml").read_text())
        assert metadata["version"] == version and metadata["appVersion"].removeprefix("v") == VERSIONS[version]
        # Synthetic hostnames only; never decrypt SOPS or inspect a live release.
        values["global"]["hosts"] = {
            "domain": "example.invalid", "gitlab": {"name": "gitlab.example.invalid"},
            "registry": {"name": "registry.example.invalid"},
        }
        with tempfile.TemporaryDirectory(prefix="gitlab-helm-test-") as tmp:
            values_file = Path(tmp) / "values.json"
            values_file.write_text(json.dumps(values))
            rendered = subprocess.check_output([
                "helm", "template", "gitlab", str(chart_dir), "--namespace", "cicd",
                "--is-upgrade", "--kube-version", kubernetes_version.split("+")[0],
                "-f", str(values_file),
            ], text=True)
        objects = yaml_json(rendered, "[.]")
        assert not any(o["kind"] in ("Gateway", "HTTPRoute", "TCPRoute") for o in objects)
        pods = [o["spec"]["template"] for o in objects if o["kind"] in ("Deployment", "StatefulSet")]
        for service in stage["externalServices"]:
            selector = service["spec"]["selector"]
            matching = [pod for pod in pods if selector.items() <= pod["metadata"]["labels"].items()]
            assert matching, service["metadata"]["name"]
            for port in service["spec"]["ports"]:
                assert any(
                    port["targetPort"] == container_port["containerPort"]
                    for pod in matching for container in pod["spec"]["containers"]
                    for container_port in container.get("ports", [])
                ), (service["metadata"]["name"], port)
        gitaly = next(o for o in objects if o["kind"] == "StatefulSet" and o["metadata"]["name"] == "gitlab-gitaly")
        assert gitaly["spec"]["volumeClaimTemplates"][0]["spec"]["resources"]["requests"]["storage"] == "50Gi"
        old_redis = any(o["kind"] == "StatefulSet" and o["metadata"]["name"] == "gitlab-redis-master" for o in objects)
        assert old_redis is not external
    print(f"OK chart {version} / GitLab {VERSIONS[version]}, external Redis={external}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--charts-dir", type=Path, help="Directory containing <chart-version>/gitlab/ from official chart archives")
    args = parser.parse_args()
    config = json.loads(subprocess.check_output([
        "nix", "eval", "--offline", "--no-write-lock-file", "--impure", "--json", "--expr", EXPR,
    ], cwd=ROOT))
    assert config["rejectsBundledRedisOnChart10"]
    assert config["defaultChartVersion"] == "10.5.4"
    assert yaml_json(config["runner"])["spec"]["version"] == "0.94.2"
    assert not config["publicSso"], "GitLab OAuth/MCP must not be intercepted by Pangolin SSO"
    assert config["postgresJob"]["metadata"]["name"] == "postgresql-gitlab-init-v2"
    sql = config["postgresJob"]["spec"]["template"]["spec"]["containers"][0]["args"][-1]
    assert "ON_ERROR_STOP=1" in sql and "gitlab_password=\"$GITLAB_PASSWORD\"" in sql
    assert "SELECT format('CREATE USER gitlab WITH PASSWORD %L', :'gitlab_password')" in sql
    for extension in ("amcheck", "btree_gist", "pg_trgm"):
        assert f"CREATE EXTENSION IF NOT EXISTS {extension};" in sql
    for stage in [*config["stages"], config["final"]]:
        check_stage(stage, args.charts_dir, config["kubernetesVersion"])
    check_startup()
    print("GitLab staged configuration and Redis safety checks passed (no deployment or authentication).")


if __name__ == "__main__":
    main()
