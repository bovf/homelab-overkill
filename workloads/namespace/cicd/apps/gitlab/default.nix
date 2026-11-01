{
  config,
  lib,
  ...
}: {
  imports = [
    ./helm.nix
    ./redis.nix
    ./middleware.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./external-services.nix
    ./lan-shell-service.nix
    ./local-dns.nix
    ./uptime.nix
  ];

  options.workloads.gitlab = {
    chartVersion = lib.mkOption {
      type = lib.types.str;
      default = "10.5.4"; # GitLab 19.5.3; native MCP is enabled by default.
      description = "GitLab chart pin. Follow UPGRADE.md; never skip required upgrade stops.";
    };
    externalRedis = lib.mkOption {
      type = lib.types.bool;
      default = lib.versionAtLeast config.workloads.gitlab.chartVersion "10.0.0";
      description = "Use the separately managed Redis workload after restoring its PVC. Enable at the 18.11 stop before moving to chart 10.";
    };
  };

  config.assertions = [
    {
      assertion = config.workloads.gitlab.externalRedis || lib.versionOlder config.workloads.gitlab.chartVersion "10.0.0";
      message = "GitLab chart 10 requires external Redis. Follow workloads/namespace/cicd/apps/gitlab/UPGRADE.md.";
    }
  ];
}
