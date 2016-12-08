require 'chef/provisioning/hanlon_driver/hanlon_driver'

['200','201','202'].each do |x|
  hanlon_ipmi "192.168.1.#{x}" do
    action :nothing
  end.run_action :power_on
  resources(execute:"Power On 192.168.1.#{x}").run_action(:run)
end
