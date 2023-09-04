#!/usr/bin/env nu
use utils.nu

export def main [] {
  restart
}

export def restart [] {
  delete
  create
}

# created k0s cluster in docker
export def create [] {
  cd (utils project-root);
  k3d cluster create -c k3d.config.yaml --registry-config ./registry.yml
  let _ = install-gateway-crds
  install-cillium

  # let _ = mount-cgroupv2;
  
    # add-insecure-registry  

    # let _ = kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml;
    init-cert-manager;
    # kubectl apply -f pool.yaml;
    # kubectl apply -f l2announcment.yaml;
    # kubectl apply -f bgppolicy.yaml;
  
  print "cluster initiated"
}

export def install-cillium [] {
  helm repo add cilium https://helm.cilium.io/
  helm install cilium cilium/cilium --version 1.15.0-pre.0 --namespace kube-system -f cilium-values.yaml
}

# created k0s cluster in docker
export def copy-kubeconfig [] {
  try {
    do { docker exec k0s cat /var/lib/k0s/pki/admin.conf | save ~/.kube/config --force } | complete
  }
}

# deletes k0s cluster
export def delete [] {
  cd (utils project-root)
  k3d cluster delete streampaicluster 
}


export def add-insecure-registry [] {
    let regConfig = 'version = 2
imports = [
  "/run/k0s/containerd-cri.toml",
]
[plugins]
[plugins."io.containerd.grpc.v1.cri"]
[plugins."io.containerd.grpc.v1.cri".registry]
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."noxy.ddns.net:5000"]
  endpoint = ["http://noxy.ddns.net:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.configs]
[plugins."io.containerd.grpc.v1.cri".registry.configs."noxy.ddns.net:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.configs."noxy.ddns.net:5000".tls]
  insecure_skip_verify = true'
      let commandString = $"\"echo '($regConfig)' > /etc/k0s/containerd.toml\""
      do {docker exec k0s-worker1 /bin/bash -c $commandString} | complete | print
      do {docker exec k0s /bin/bash -c $commandString} | complete | print
  
}

export def install-gateway-crds [] {
  let manifests = [
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.1/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.1/config/crd/standard/gateway.networking.k8s.io_gateways.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.1/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.1/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml"
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.1/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml"    
  ]
  $manifests | par-each { kubectl apply -f $in } 
}

export def init-cert-manager [] {
    # kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    (helm install cert-manager 
      --version v1.10.0
      --namespace cert-manager 
      --set installCRDs=true
      --create-namespace
      --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}"
      jetstack/cert-manager)
}
