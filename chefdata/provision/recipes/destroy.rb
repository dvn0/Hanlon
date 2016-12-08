# Clean up data bags if we are destroying everything

include_recipe "provision::node_state"
master = node.run_state['provision']['master']
workers = node.run_state['provision']['workers']
all_nodes = node.run_state['provision']['all_nodes']

all_nodes.each do |n|
  file "#{Chef::Config.file_cache_path}/#{n['ip']}.pem" do
    action :delete
  end
  file "#{Chef::Config.file_cache_path}/#{n['ip']}-key.pem" do
    action :delete
  end
  file "#{Chef::Config.file_cache_path}/#{n['ip']}.csr" do
    action :delete
  end
end

file "#{Chef::Config.file_cache_path}/openssl.cnf" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/worker-openssl.cnf" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/ca.pem" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/ca-key.pem" do
  action :delete
end

file "#{Chef::Config.file_cache_path}/admin.pem" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/admin-key.pem" do
  action :delete
end

file "#{Chef::Config.file_cache_path}/ca.srl" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/apiserver.csr" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/admin.csr" do
  action :delete
end


file "#{Chef::Config.file_cache_path}/admin.csr" do
  action :delete
end


file "/usr/local/bin/kubectl" do
  action :delete
end

file "#{Chef::Config.file_cache_path}/provisioning.pem" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/provisioning.pem.pub" do
  action :delete
end
file "#{Chef::Config.file_cache_path}/known_hosts" do
  action :delete
end

chef_data_bag 'discovery' do
  action :delete
end

chef_data_bag 'hanlon_node' do
  action :delete
end

hanlon_tag "serialnumber" do
  action :delete
  field "serialnumber"
end

ruby_block "Remove all Active Models" do
  block do
    Hanlon::Api::ActiveModel.list.each do |active_model|
      Hanlon::Api::ActiveModel.destroy(active_model)
    end
  end
end

ruby_block "Remove all Policies" do
  block do
    Hanlon::Api::Policy.list.each do |policy|
      Hanlon::Api::Policy.destroy(policy)
    end
  end
end

ruby_block "Remove all Models" do
  block do
    Hanlon::Api::Model.list.each do |model|
      Hanlon::Api::Model.destroy(model)
    end
  end
end

ruby_block "Remove all Nodes" do
  block do
    Hanlon::Api::Node.list.each do |node|
      Hanlon::Api::Node.destroy(node)
    end
  end
end

include_recipe 'provision::power_off'

# FIXME
# hanlon_policy "ii-master-#{master['serialnumber']}" do
#   action :delete
# end if master

# hanlon_model "ii-master-#{master['serialnumber']}" do
#   action :delete
# end if master

# workers.each do |worker|
#   hanlon_policy "ii-worker-#{worker['serialnumber']}" do
#     action :delete
#   end
#   hanlon_model "ii-worker-#{worker['serialnumber']}" do
#     action :delete
#   end
# end if workers

#include_recipe "provision::certs"
#it detects destroys

