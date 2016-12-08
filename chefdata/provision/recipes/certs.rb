master = node.run_state['provision']['master']
workers = node.run_state['provision']['workers']
all_nodes = node.run_state['provision']['all_nodes']

directory "#{Chef::Config.file_cache_path}" do
  recursive true
end.run_action :create

execute 'generate ca' do
  action :nothing
  creates "#{Chef::Config.file_cache_path}/ca.pem"
  cwd Chef::Config.file_cache_path
  command <<EOF
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"
EOF
end.run_action :run

file "#{Chef::Config.file_cache_path}/openssl.cnf" do
  action :nothing
  content <<EOF
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [ v3_req ]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = kubernetes
  DNS.2 = kubernetes.default
  DNS.3 = kubernetes.default.svc
  DNS.4 = kubernetes.default.svc.cluster.local
  IP.1 = #{node['provision']['k8s']['k8s_service_ip']}
  IP.2 = #{master['ip']}
EOF
end.run_action :create

file "#{Chef::Config.file_cache_path}/worker-openssl.cnf" do
  action :nothing
  content <<EOF
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [ v3_req ]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment
  subjectAltName = @alt_names
  [alt_names]
  IP.1 = $ENV::WORKER_IP
EOF
end.run_action :create

execute 'generate apiserver key and cert' do
  action :nothing
  creates "#{Chef::Config.file_cache_path}/#{master['ip']}.pem"
  #creates "#{Chef::Config.file_cache_path}/apiserver.pem"
  cwd Chef::Config.file_cache_path
  command <<EOF
openssl genrsa -out #{master['ip']}-key.pem 2048
openssl req -new -key #{master['ip']}-key.pem -out #{master['ip']}.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in #{master['ip']}.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out #{master['ip']}.pem -days 365 -extensions v3_req -extfile openssl.cnf
EOF
end.run_action :run

workers.each do |worker|
  execute "generate worker #{worker['ip']} key and cert" do
    action :nothing
    creates "#{Chef::Config.file_cache_path}/#{worker['ip']}.pem"
    cwd Chef::Config.file_cache_path
    env({
      'WORKER_FQDN' => worker['ip'],
      'WORKER_IP' => worker['ip'],
    })
    command <<EOF
openssl genrsa -out ${WORKER_FQDN}-key.pem 2048
WORKER_IP=${WORKER_IP} openssl req -new -key ${WORKER_FQDN}-key.pem -out ${WORKER_FQDN}.csr -subj "/CN=#{worker['serialnumber']}" -config worker-openssl.cnf
WORKER_IP=${WORKER_IP} openssl x509 -req -in ${WORKER_FQDN}.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${WORKER_FQDN}.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf
EOF
  end.run_action :run
end

execute 'generate admin key and cert' do
  action :nothing
  creates "#{Chef::Config.file_cache_path}/admin.pem"
  #creates "#{Chef::Config.file_cache_path}/apiserver.pem"
  cwd Chef::Config.file_cache_path
  command <<EOF
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365
EOF
end.run_action :run

node.run_state['pems'] = {}
node.run_state['provision']['all_nodes'].each do |n|
  node.run_state['pems'][n['ip']] = {
    key: open("#{Chef::Config.file_cache_path}/#{n['ip']}-key.pem").read(),
    pem: open("#{Chef::Config.file_cache_path}/#{n['ip']}.pem").read()
  }
end
