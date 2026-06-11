{...}: {
  workloads.uptimeMonitors.matrix = {
    name = "Matrix Homeserver";
    domainKey = "pangolin/resources/matrix/domain";
    path = "/_matrix/client/versions";
    group = "Comms";
  };
}
