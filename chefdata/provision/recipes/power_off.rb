require 'chef/provisioning/hanlon_driver/hanlon_driver'

hanlon_ipmi '192.168.1.200' do
  action :power_off
end
hanlon_ipmi '192.168.1.201' do
  action :power_off
end
hanlon_ipmi '192.168.1.202' do
  action :power_off
end
