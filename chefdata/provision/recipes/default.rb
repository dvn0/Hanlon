require 'chef/provisioning'
require 'chef/provisioning/hanlon_driver/hanlon_driver'
require 'chef/provisioning/ssh_driver'
with_driver 'hanlon:192.168.1.128:8026/hanlon/api/v1'
Hanlon::Api.configure do |c|
  c.api_url = run_context.chef_provisioning.current_driver.sub(
    'hanlon:','http://')
end
context = ChefDK::ProvisioningData.context
#context.action :converge / :destroy
if context.action == :destroy
  include_recipe "provision::destroy"
else
  include_recipe "provision::main"
end
