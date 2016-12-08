master = node.run_state['provision']['master']
workers = node.run_state['provision']['workers']

discovery_url = search(:discovery,'id:url').first['etcd']
etcd_servers = node.run_state['provision']['all_nodes'].map do |n|
  "http://#{n['ip']}:2379"
end.join(',')

ca_pem = open("#{Chef::Config.file_cache_path}/ca.pem").read()
apiserver_pem = node.run_state['pems'][master['ip']][:pem]
apiserver_key_pem = node.run_state['pems'][master['ip']][:key]
ssh_pub_key = node.run_state['provisioning']['ssh_pub_key']

node.run_state['cloud_config'] ||= {}
node.run_state['cloud_config'][master['ip']] = {
  ssh_authorized_keys:
    [
      ssh_pub_key
    ],
  coreos: {
    units: [
      { name: "etcd2.service", command: "start", enable: true}
#      { name: "flanneld.service", command: "start", enable: true},
#      { name: "kubelet.service", command: "start", enable: true}
    ],
    etcd2: {
      'name' => "infra0",
      'discovery' => discovery_url,
      'advertise-client-urls' => "http://#{master['ip']}:2379",
      'initial-advertise-peer-urls' => "http://#{master['ip']}:2380",
      'listen-client-urls' => "http://#{master['ip']}:2379,http://127.0.0.1:2379",
      'listen-peer-urls' => "http://#{master['ip']}:2380"
    }
  },
  write_files: [
    {path: "/etc/kubernetes/ssl/ca.pem",
     owner: "root:root",
     permissions: 600,
     content: ca_pem},
    {path: "/etc/kubernetes/ssl/apiserver.pem",
     owner: "root:root",
     permissions: 600,
     content: apiserver_pem},
    {path: "/etc/kubernetes/ssl/apiserver-key.pem",
     owner: "root:root",
     permissions: 600,
     content: apiserver_key_pem},
    {path: "/etc/flannel/options.env",
     owner: "core:core",
     permissions: 420,
     content:
       "FLANNELD_IFACE=#{master['ip']}
FLANNELD_ETCD_ENDPOINTS=#{etcd_servers}
"},
    {path:  "/etc/systemd/system/flanneld.service.d/40-ExecStartPre-symlink.conf",
     owner: "root:root",
     permissions: 420,
     content:
       "[Service]
ExecStartPre=/usr/bin/ln -sf /etc/flannel/options.env /run/flannel/options.env
"},
    {path: "/etc/systemd/system/docker.service.d/40-flannel.conf",
     owner: "root:root",
     permissions: 420,
     content:
       "[Unit]
Requires=flanneld.service
After=flanneld.service
"},
    {path: "/etc/systemd/system/kubelet.service",
     owner: "root:root",
     permissions: 420,
     content:
       "[Service]
ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
ExecStartPre=/usr/bin/mkdir -p /var/log/containers
Environment=KUBELET_VERSION=v1.4.3_coreos.0
Environment=\"RKT_OPTS=--volume var-log,kind=host,source=/var/log \\
  --mount volume=var-log,target=/var/log \\
  --volume dns,kind=host,source=/etc/resolv.conf \\
  --mount volume=dns,target=/etc/resolv.conf\"
ExecStart=/usr/lib/coreos/kubelet-wrapper \\
  --api-servers=http://127.0.0.1:8080 \\
  --network-plugin-dir=/etc/kubernetes/cni/net.d \\
  --network-plugin= \\
  --register-schedulable=false \\
  --allow-privileged=true \\
  --config=/etc/kubernetes/manifests \\
  --hostname-override=#{master['ip']} \\
  --cluster-dns=#{node['provision']['k8s']['dns_service_ip']} \\
  --cluster-domain=cluster.local
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
"},
    {path: "/etc/kubernetes/manifests/kube-apiserver.yaml",
     owner: "core:core",
     permissions: 420,
     content:
       "apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-apiserver
    image: quay.io/coreos/hyperkube:v1.4.3_coreos.0
    command:
    - /hyperkube
    - apiserver
    - --bind-address=0.0.0.0
    - --etcd-servers=#{etcd_servers}
    - --allow-privileged=true
    - --service-cluster-ip-range=#{node['provision']['k8s']['service_ip_range']}
    - --secure-port=443
    - --advertise-address=#{master['ip']}
    - --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota
    - --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem
    - --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --client-ca-file=/etc/kubernetes/ssl/ca.pem
    - --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --runtime-config=extensions/v1beta1=true,extensions/v1beta1/networkpolicies=true
    ports:
    - containerPort: 443
      hostPort: 443
      name: https
    - containerPort: 8080
      hostPort: 8080
      name: local
    volumeMounts:
    - mountPath: /etc/kubernetes/ssl
      name: ssl-certs-kubernetes
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/ssl
    name: ssl-certs-kubernetes
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
"},
    {path: "/etc/kubernetes/manifests/kube-proxy.yaml",
     owner: "core:core",
     permissions: 420,
     content:
       "apiVersion: v1
kind: Pod
metadata:
  name: kube-proxy
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-proxy
    image: quay.io/coreos/hyperkube:v1.4.3_coreos.0
    command:
    - /hyperkube
    - proxy
    - --master=http://127.0.0.1:8080
    - --proxy-mode=iptables
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
"},
    {path: "/etc/kubernetes/manifests/kube-controller-manager.yaml",
     owner: "core:core",
     permissions: 420,
     content:
         "apiVersion: v1
kind: Pod
metadata:
  name: kube-controller-manager
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-controller-manager
    image: quay.io/coreos/hyperkube:v1.4.3_coreos.0
    command:
    - /hyperkube
    - controller-manager
    - --master=http://127.0.0.1:8080
    - --leader-elect=true
    - --service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --root-ca-file=/etc/kubernetes/ssl/ca.pem
    livenessProbe:
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10252
      initialDelaySeconds: 15
      timeoutSeconds: 1
    volumeMounts:
    - mountPath: /etc/kubernetes/ssl
      name: ssl-certs-kubernetes
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/ssl
    name: ssl-certs-kubernetes
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
"},
    {path: "/etc/kubernetes/manifests/kube-scheduler.yaml",
     owner: "core:core",
     permissions: 420,
     content:
       "apiVersion: v1
kind: Pod
metadata:
  name: kube-scheduler
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-scheduler
    image: quay.io/coreos/hyperkube:v1.4.3_coreos.0
    command:
    - /hyperkube
    - scheduler
    - --master=http://127.0.0.1:8080
    - --leader-elect=true
    livenessProbe:
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10251
      initialDelaySeconds: 15
      timeoutSeconds: 1
"},

  ]
}

 
