execute 'Create Provisioning SSH Key' do
  creates "#{Chef::Config.file_cache_path}/provisioning.pem"
  command "ssh-keygen -b 2048 -t rsa -f #{Chef::Config.file_cache_path}/provisioning.pem -N ''"
end.run_action :run

node.run_state['provisioning'] ||= {}
node.run_state['provisioning']['ssh_pub_key'] = open(
  "#{Chef::Config.file_cache_path}/provisioning.pem.pub"
).read()
node.run_state['provisioning']['ssh_key'] = open(
  "#{Chef::Config.file_cache_path}/provisioning.pem"
).read()


