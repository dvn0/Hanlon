master = node.run_state['provision']['master']
workers = node.run_state['provision']['workers']

discovery_url = search(:discovery,'id:url').first['etcd']
etcd_servers = node.run_state['provision']['all_nodes'].map do |n|
  "http://#{n['ip']}:2379"
end.join(',')

ca_pem = open("#{Chef::Config.file_cache_path}/ca.pem").read()
ssh_pub_key = node.run_state['provisioning']['ssh_pub_key']

node.run_state['cloud_config'] ||= {}
workers.each do |w|
  worker_pem = node.run_state['pems'][w['ip']][:pem]
  worker_key_pem = node.run_state['pems'][w['ip']][:key]
  node.run_state['cloud_config'][w['ip']] = {
    ssh_authorized_keys:
      [
        ssh_pub_key
      ],
    coreos: {
      units: [
        { name: "etcd2.service", command: "start", enable: true},
#        { name: "flanneld.service", command: "start", enable: true},
#        { name: "kubelet.service", command: "start", enable: true}
      ],
      etcd2: {
        #name: "infra0", #maybe blank, checking FIXME
        discovery: discovery_url,
        'advertise-client-urls': "http://#{w['ip']}:2379",
              'initial-advertise-peer-urls': "http://#{w['ip']}:2380",
              'listen-client-urls': "http://#{w['ip']}:2379,http://127.0.0.1:2379",
              'listen-peer-urls': "http://#{w['ip']}:2380"
      }
    },
    write_files: [
      {path: "/etc/kubernetes/ssl/ca.pem",
       owner: "root:root",
       permissions: 600,
       content: ca_pem},
      {path: "/etc/kubernetes/ssl/worker.pem",
       owner: "root:root",
       permissions: 600,
       content: ca_pem},
      {path: "/etc/kubernetes/ssl/worker.pem",
       owner: "root:root",
       permissions: 600,
       content: worker_pem},
      {path: "/etc/kubernetes/ssl/worker-key.pem",
       owner: "root:root",
       permissions: 600,
       content: worker_key_pem},
      {path: "/etc/flannel/options.env",
       owner: "core:core",
       permissions: 420,
       content:
         "FLANNELD_IFACE=#{w['ip']}
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
      {path: "/etc/kubernetes/worker-kubeconfig.yaml",
       owner: "core:core",
       permissions: 420,
       content:
         "apiVersion: v1
kind: Config
clusters:
- name: local
  cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
users:
- name: kubelet
  user:
    client-certificate: /etc/kubernetes/ssl/worker.pem
    client-key: /etc/kubernetes/ssl/worker-key.pem
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
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
  --api-servers=https://#{master['ip']} \\
  --network-plugin-dir=/etc/kubernetes/cni/net.d \\
  --network-plugin= \\
  --register-node=true \\
  --allow-privileged=true \\
  --config=/etc/kubernetes/manifests \\
  --hostname-override=#{w['ip']} \\
  --cluster-dns=#{node['provision']['k8s']['dns_service_ip']} \\
  --cluster-domain=cluster.local \\
  --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml \\
  --tls-cert-file=/etc/kubernetes/ssl/worker.pem \\
  --tls-private-key-file=/etc/kubernetes/ssl/worker-key.pem
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
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
    - --master=https://#{master['ip']}
    - --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml
    - --proxy-mode=iptables
    securityContext:
      privileged: true
    volumeMounts:
      - mountPath: /etc/ssl/certs
        name: \"ssl-certs\"
      - mountPath: /etc/kubernetes/worker-kubeconfig.yaml
        name: \"kubeconfig\"
        readOnly: true
      - mountPath: /etc/kubernetes/ssl
        name: \"etc-kube-ssl\"
        readOnly: true
  volumes:
    - name: \"ssl-certs\"
      hostPath:
        path: \"/usr/share/ca-certificates\"
    - name: \"kubeconfig\"
      hostPath:
        path: \"/etc/kubernetes/worker-kubeconfig.yaml\"
    - name: \"etc-kube-ssl\"
      hostPath:
        path: \"/etc/kubernetes/ssl\"
"},
    ]
  }
end
