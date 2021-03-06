## recipe: configure.rb

# Ensure SELinux is disabled
execute 'disable_selinux' do
  command 'setenforce 0'
  only_if 'getenforce | grep Disabled'
end

# Main cobbler configuration file
template '/etc/cobbler/settings.yaml' do
  source 'settings.yaml.erb'
  notifies :restart, 'service[cobblerd]'
end

# Enable and start the Cobbler daemon
service 'cobblerd' do
  action [ :enable, :start ]
end

# Give cobblerd extra time to bake. Otherwise, 'cobbler_sync' may run into issues.
chef_sleep '5'

# DHCP configuration template
template '/etc/cobbler/dhcp.template' do
  source 'dhcp.template.erb'
  notifies :run, 'execute[cobbler_sync]', :immediately
end

# Cobbler sync command - invoked when updates to dhcp.template are made or when new distros are added.
execute 'cobbler_sync' do
  command 'cobbler sync'
  action :nothing
end

node['cobbler3']['configure']['supporting_services'].each do |svc|
  service svc do
    action [ :enable, :start ]
  end
end

## Retrieve, mount, and persist ISO images
node['cobbler3']['configure']['distros'].each do |name, link, arch|
  remote_file "/opt/#{name}" do
    source link
  end

  directory "/mnt/#{name}" do
    recursive true
  end

  mount "/mnt/#{name}" do
    device "/opt/#{name}"
    fstype 'iso9660'
    options 'loop,ro'
    action [:mount, :enable]
    not_if "df | grep -i #{name}"
  end

  execute 'import distro' do
    command "cobbler import --name=#{name} --arch=#{arch} --path=/mnt/#{name}"
    not_if "cobbler distro list | grep -i #{name}"
    notifies :run, 'execute[cobbler_sync]', :immediately
  end
end
