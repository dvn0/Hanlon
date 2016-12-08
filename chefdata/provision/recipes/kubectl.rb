master = node.run_state['provision']['master']

remote_file '/usr/local/bin/kubectl' do
  source "https://storage.googleapis.com/kubernetes-release/release/v1.4.3/bin/linux/#{node['provision']['k8s']['kubectl']['arch']}/kubectl"
  checksum node['provision']['k8s']['kubectl']['sha']
  mode 0755
end

execute 'configure kubectl' do
  command <<EOF
kubectl config set-cluster default-cluster --server=https://#{master['ip']} --certificate-authority=#{Chef::Config.file_cache_path}/ca.pem
kubectl config set-credentials default-admin --certificate-authority=#{Chef::Config.file_cache_path}/ca.pem --client-key=#{Chef::Config.file_cache_path}/admin-key.pem --client-certificate=#{Chef::Config.file_cache_path}/admin.pem
kubectl config set-context default-system --cluster=default-cluster --user=default-admin
kubectl config use-context default-system
EOF
end
