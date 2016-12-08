node_count = ENV['NODE_COUNT'] || 3
node_count = node_count.to_i

chef_data_bag 'discovery' do
end.run_action :create

chef_data_bag 'hanlon_node' do
end.run_action :create

chef_data_bag_item 'discovery/url' do
  raw_data({
             'etcd' => Net::HTTP.get(URI.parse("https://discovery.etcd.io/new?size=#{node_count}"))
           })
end.run_action(:create) if search(:discovery,'id:url').empty?

ruby_block "Wait for #{node_count} nodes..." do
  block do
    puts ''
    loop do
      if Hanlon::Api::Node.list.length >= node_count
        Hanlon::Api::Node.list.each do |node_uuid|
          n = Hanlon::Api::Node.find(node_uuid)
          item_name = n.attributes_hash['serialnumber'] || n.hw_id.first
          data = JSON.parse(n.to_json).merge({'id' => item_name})
          hanlon_node = Chef::DataBagItem.new
          hanlon_node.data_bag('hanlon_node')
          hanlon_node.raw_data = data
          hanlon_node.save
          Chef::Log.warn("Saving hanlon_node/#{item_name}")
        end
        break
      else
        sleeptime = 30
        Chef::Log.warn("Waiting #{sleeptime} seconds for (#{Hanlon::Api::Node.list.length}/#{node_count}) nodes.. ")
        sleep sleeptime
      end
    end
  end
end.run_action :run

#current_dir = File.dirname(__FILE__)
# remote_file "#{current_dir}/../web/coreos_production_iso_image-1185.3.0.iso" do
#   source 'https://stable.release.core-os.net/amd64-usr/1185.3.0/coreos_production_iso_image.iso'
#   checksum '1601e88e17d0dc62e6f8617a0d2f2c844c41a79c54f7e3780e23a256e4e1b1bd' #sha256sum
# end

# hanlon_image 'coreos_production_iso_image-1185.3.0.iso' do
#   type 'os'
#   version '1185.3.0'
#   description 'CoreOS stable 1185'
# end


