master = node.run_state['provision']['master']
workers = node.run_state['provision']['workers']
# Since we are using our own logic for now
# Each node can be chosen via it's serialnumber
hanlon_tag "serialnumber" do
  field "serialnumber"
end

hanlon_model "ii-master-#{master['serialnumber']}" do
  image 'CoreOSv1185.3.0.iso'
  template 'coreos_stable'
  metadata ({
              hostname_prefix: 'ii-master',
              domainname: 'ii.coop',
              install_disk: '/dev/sda',
              cloud_config: node.run_state['cloud_config'][master['ip']]
            })
end

hanlon_policy "ii-master-#{master['serialnumber']}" do
  model "ii-master-#{master['serialnumber']}"
  template 'linux_deploy'
  tags master['serialnumber']
  maximum 1
end

workers.each do |worker|
  hanlon_model "ii-worker-#{worker['serialnumber']}" do
    image 'CoreOSv1185.3.0.iso'
    template 'coreos_stable'
    metadata ({
                hostname_prefix: "ii-worker-#{worker['serialnumber']}",
                domainname: 'ii.coop',
                install_disk: '/dev/sda',
                cloud_config: node.run_state['cloud_config'][worker['ip']]
              })
  end

  hanlon_policy "ii-worker-#{worker['serialnumber']}" do
    model "ii-worker-#{worker['serialnumber']}"
    template 'linux_deploy'
    tags worker['serialnumber']
    maximum 1
  end
end

node_count = ENV['NODE_COUNT'] || 3
node_count = node_count.to_i

ruby_block "Wait for #{node_count} node logs to show available..." do
  block do
    puts ''
    node.run_state['logs'] = {}
    loop do
      if Hanlon::Api::ActiveModel.list.length >= node_count
        Hanlon::Api::ActiveModel.list.each do |active_model|
          am = Hanlon::Api::ActiveModel.find(active_model)
          next unless am.node
          serialnumber = am.node['@attributes_hash']['serialnumber']
          node.run_state['logs'][serialnumber] ||= []
          am.logs.each do |log|
            unless node.run_state['logs'][serialnumber].include? log
              node.run_state['logs'][serialnumber] << log
              Chef::Log.warn("#{serialnumber}: state: #{log['state']}, action: #{log['action']}, method: #{log['method']}, result: #{log['result']}")
            end
          end
        end
        uniq_last_log_states = node.run_state['logs'].values.map{|v|v.last["state"]}.uniq
        next unless uniq_last_log_states == ["complete_no_broker"]
        Chef::Log.warn("All #{node_count} nodes are avaliable")
        break
      else
        sleeptime = 30
        Chef::Log.warn("Waiting #{sleeptime} seconds for (#{Hanlon::Api::ActiveModel.list.length}/#{node_count}) nodes.. ")
        sleep sleeptime
      end
    end
  end
end
