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
  use k8s_utils/kubernetes.nu;
  kubernetes load-kernel-modules
  
  k3d cluster create -c k3d.config.yaml --registry-config ./registry.yml

  enter k8s_utils
  kubernetes install-gateway-crds
  kubernetes install-cilium
  kubernetes install-openebs
  kubernetes install-certmanager
  dexit

  kubectl apply -f gateway.yaml
  ./k8s_utils/annotate-gateways.nu --ip 172.17.0.2 --ipPool 172.17.0.2/24
}


# deletes k0s cluster
export def delete [] {
  cd (utils project-root)
  k3d cluster delete streampaicluster 
}



export def mount-cgroupv2 [] {
  try {
    do {
      sudo mkdir /run/cilium/cgroupv2
      sudo mount --bind -t cgroup2 /run/cilium/cgroupv2 /run/cilium/cgroupv2
      sudo mount --make-shared /run/cilium/cgroupv2
      print "Done mounting cgroupv2"
    } | complete
  }
}

