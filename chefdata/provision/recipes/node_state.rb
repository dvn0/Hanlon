begin
  k8s_nodes = search(
    :hanlon_node, '*:*',
    :filter_result => {
      'hw_id' => [ 'hw_id' ],
      'ip' => [ 'attributes_hash','ipaddress_eth0' ],
      'cpu_count' => ['attributes_hash','processorcount'],
      'memory' => ['attributes_hash','memorysize_mb'],
      'manufacturer' => ['attributes_hash','manufacturer'],
      'productname' => ['attributes_hash','productname'],
      'serialnumber' => ['attributes_hash','serialnumber'],
    }
  ).sort_by{|k,v| k['cpu_count'].to_i}
rescue
  k8s_nodes = []
end
  k8s_nodes.each do |n|
  Chef::Log.warn("#{n['manufacturer']} #{n['productname']} \
serial: #{n['serial']} \
ip:#{n['ip']} \
cores:#{n['cpu_count']} \
memory:#{n['memory']} \
hw_id:#{n['hw_id'].first} \
")
end

master = k8s_nodes.first
workers = k8s_nodes[1..-1]

node.run_state['provision'] ||= {}
node.run_state['provision']['master'] = master
node.run_state['provision']['workers'] = workers
node.run_state['provision']['all_nodes'] = k8s_nodes
