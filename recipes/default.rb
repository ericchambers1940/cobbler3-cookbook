# Default recipe. Only serves to call other recipes in a specific order.
#

platform = node['platform']

if platform.eql?('centos') || platform.eql?('oracle')
  include_recipe 'cobbler3::install'
  include_recipe 'cobbler3::configure'
else
  Chef::Log.warn("WARNING, WARNING - This cookbook has ONLY been tested on CentOS 8 and may not work on #{platform}")
end
