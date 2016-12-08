include_recipe "provision::power_on"
include_recipe "provision::node_setup"
include_recipe "provision::node_state"
include_recipe "provision::certs"
include_recipe "provision::ssh_key"
include_recipe "provision::master_cloud_config"
include_recipe "provision::worker_cloud_config"
include_recipe "provision::hanlon"
include_recipe "provision::via_ssh"
include_recipe "provision::kubectl"
ruby_block 'install gitlab on kubernetes' do
  block do
    require 'pry-byebug'
    binding.pry
  end

end

files_path = [Chef::Config[:cookbook_path],cookbook_name.to_s,'files'].join('/')
execute 'install gitlab on kubernetes' do
  command <<EOF
kubectl create -f gitlab-ns.yml
kubectl create -f redis-svc.yml
kubectl create -f svc-postgresql.yml
kubectl create -f postgresql-deployment.yml
kubectl create -f redis-deployment.yml
kubectl create -f gitlab-deployment.yml
kubectl create -f gitlab-svc.yml
kubectl create -f configmap.yml
kubectl create -f nginx-settings-configmap.yml
kubectl create -f default-backend-svc.yml
kubectl create -f default-backend-deployment.yml
kubectl create -f nginx-ingress-lb.yml
kubectl create -f gitlab-ingress.yml
  EOF
end
