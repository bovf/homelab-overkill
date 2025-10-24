{ ... }:

{
  services.k3s.manifests.newt.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "newt";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.jeffresc.dev";
      chart = "newt";
      version = "0.1.2";
      targetNamespace = "pangolin";
      createNamespace = false;
      valuesContent = ''
        pangolin:
          endpoint: "https://pangolin.dobryops.com"
  
        secret:
          name: "newt-secrets"
          id:
            key: "newt_id"
          secret:
            key: "newt_secret"
  
        image:
          repository: fosrl/newt
          tag: "1.2.1"
      '';
    };
  };
}
