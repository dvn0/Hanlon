require 'pry-byebug'
require 'chef/provisioning/ssh_driver'

include_recipe "provision::node_state"
master_node = node.run_state['provision']['master']
workers = node.run_state['provision']['workers']
all_nodes = node.run_state['provision']['all_nodes']

all_nodes.each do |n|
  machine "#{n['serialnumber']}" do
    driver 'ssh'
    #action [:ready, :setup] #, :converge]
    #    action :nothing
    action :ready
    machine_options :ssh_timeout => 600,
                    :transport_options => {
                      'ip_address' => n['ip'],
                      'username' => 'core',
                      'ssh_options' => {
                        #'paranoid' => false,
                        'user_known_hosts_file' => "#{Chef::Config.file_cache_path}/known_hosts",
                        'keys' => [
                          "#{Chef::Config.file_cache_path}/provisioning.pem"
                        ]
                      }
                    }
  end
end

#Chef::Provisioning::Machine#methods: detect_os  machine_spec  name  node
#Chef::Provisioning::Machine::BasicMachine#methods:
#cleanup_convergence  converge  convergence_strategy  disconnect  download_file
# execute  execute_always  make_url_available_to_remote  read_file
# setup_convergence  transport  upload_file  write_file
#Chef::Provisioning::Machine::UnixMachine#methods:
# create_dir  delete_file  dirname_on_machine
# file_exists?  files_different?  get_attributes  is_directory?
# options  set_attributes
# instance variables: @convergence_strategy  @machine_spec  @tmp_dir  @transport

ruby_block 'configure the master via ssh' do
  block do
    mr=resources(machine: master_node['serialnumber']).provider_for_action(:ready)
    mr.load_current_resource
    master=mr.action_ready
    flannel_init=master.execute_always("curl -X PUT -d \
'value={\
\"Network\":\"#{node['provision']['k8s']['pod_network']}\",\
\"Backend\":{\"Type\":\"vxlan\"}}' \
'http://#{master_node['ip']}:2379/v2/keys/coreos.com/network/config'")
    Chef::Log.warn "Flannel Init Success: #{flannel_init.exitstatus == 0}"

    flannel_start=master.execute_always("sudo systemctl start flanneld")
    Chef::Log.warn "Flannel Start Success: #{flannel_start.exitstatus == 0}"
    flannel_enable=master.execute_always("sudo systemctl enable flanneld")
    Chef::Log.warn "Flannel Enable Success: #{flannel_enable.exitstatus == 0}"

    kubelet_start=master.execute_always("sudo systemctl start kubelet")
    Chef::Log.warn "Kubelet Start Success: #{kubelet_start.exitstatus == 0}"
    kubelet_enable=master.execute_always("sudo systemctl enable kubelet")
    Chef::Log.warn "Kubelet Start Success: #{kubelet_enable.exitstatus == 0}"

    loop do
      api_check=master.execute_always("curl http://127.0.0.1:8080/version")
      break if api_check.exitstatus == 0
      Chef::Log.warn "API Start Status: #{api_check.exitstatus}, Waiting"
      sleep 60
    end

    namespace_init=master.execute_always('curl -H "Content-Type: application/json" \
-XPOST \
-d\'{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"kube-system"}}\' \
"http://127.0.0.1:8080/api/v1/namespaces"')
    Chef::Log.warn "Namespace Init Success: #{namespace_init.exitstatus == 0}"
  end
end

ruby_block 'configure the minions via ssh' do
  block do
    puts ''
    workers.each do |w|
      mr=resources(machine: w['serialnumber']).provider_for_action(:ready)
      mr.load_current_resource
      worker=mr.action_ready

      kubelet_start=worker.execute_always("sudo systemctl start kubelet")
      Chef::Log.warn "Minion #{w['serialnumber']} Kubelet Start Success: #{kubelet_start.exitstatus == 0}"
      kubelet_enable=worker.execute_always("sudo systemctl enable kubelet")
      Chef::Log.warn "Minion #{w['serialnumber']} Kubelet Enable Success: #{kubelet_enable.exitstatus == 0}"
    end
  end
end
