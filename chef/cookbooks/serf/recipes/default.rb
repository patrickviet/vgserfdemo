include_recipe 'runit'

# Hack to make this work with Smarstack
group 'smartstack'
user 'smartstack' do
  group 'smartstack'
  shell '/sbin/nologin'
  home '/opt/smartstack'
end

package 'unzip'

# For some reason ark was messing up so it's done manually here...

remote_file "#{Chef::Config[:file_cache_path]}/serf_0.5.0_linux_amd64.zip" do
  source "https://dl.bintray.com/mitchellh/serf/0.5.0_linux_amd64.zip"
  notifies :run, 'execute[unzip serf]'
end

execute 'unzip serf' do
  command "unzip -o #{Chef::Config[:file_cache_path]}/serf_0.5.0_linux_amd64.zip"
  cwd "/usr/local/bin"

  action :nothing
  if File.exists? '/usr/local/bin/serf'
    if File.stat('/usr/local/bin/serf').size == 0
      action :run
    end
  else
    action :run
  end
end

file '/usr/local/bin/serf' do
  owner 'root'
  group 'smartstack'
  mode '0750'
end

directory '/etc/serf' do
  mode '0775'
  owner 'root'
  group 'smartstack'
end

bindip = node.ipaddress
if node.ipaddress =~ /(^127\.0\.0\.1)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)/
  # private ip

  # are we in Vagrant?
  if node.filesystem.has_key? '/vagrant'
    if node.network.interfaces.has_key? 'eth1'
      ad = node.network.interfaces.eth1.addresses
      ip = nil
      # take the first ipv4 from that list
      ad.keys.each do |tryip|
        if tryip =~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/
          ip = tryip
          bindip = tryip
          break
        end
      end

      if ip
        file '/etc/serf/publicv4.json' do
          mode '0640'
          owner 'root'
          group 'smartstack'
          content "{\"advertise\":\"#{ip}\"}\n"
          notifies :run, 'execute[killall serf]'
        end
      end
    end
  else

    # let's assume we're on ec2. ohai is messed up so I'll initialize it.
    node.default.ec2 = {} unless node.has_key? 'ec2'

    # let's try if I get something from curl
    ip=`curl -s --connect-timeout 2 --retry 1 http://169.254.169.254/latest/meta-data/public-ipv4`
    if ip =~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/
      # we got an IP
      file '/etc/serf/publicv4.json' do
        mode '0640'
        owner 'root'
        group 'smartstack'
        content "{\"advertise\":\"#{ip}\"}\n"
        notifies :run, 'execute[killall serf]'
      end
    else
      file '/etc/serf/publicv4.json' do
        action :delete
        # no notification. I don't want to break serf in case 169.254.169.254 is broken.
      end
    end
  end
else
  file '/etc/serf/publicv4.json' do
    action :delete
    notifies :run, 'execute[killall serf]'
  end
end

file '/etc/serf/generic.json' do
  mode '0640' # secure! contains secrets
  owner 'root'
  group 'smartstack'
  content JSON.pretty_generate({
    encrypt_key: node.serf.shared_key,
    start_join: node.serf.masters,   # MUST BE AN ARRAY
    bind: bindip,
    profile: 'lan',
    snapshot: '/dev/shm/serf_workfile',
    node_name: node.hostname

  })
  notifies :run, 'execute[killall serf]'
end

if File.exists?('/etc/chef/role') and File.exists?('/etc/chef/branch')

  file '/etc/serf/chef_tags.json' do
    mode '0640' # secure! contains secrets
    owner 'root'
    group 'smartstack'
    content JSON.pretty_generate({'tags' => {
      chef_role: File.read('/etc/chef/role').strip,
      chef_branch: File.read('/etc/chef/branch').strip,
    }})
    notifies :run, 'execute[reload serf]'
  end
end

cookbook_file '/etc/serf/synapse.json' do
  mode '0640'
  owner 'root'
  group 'smartstack'
  notifies :run, 'execute[reload serf]'
end


execute 'reload serf' do
  command 'killall -HUP serf || true'
  action :nothing
end

execute 'killall serf' do
  command 'killall serf || true' # the ||true means it can fail - silently
  action :nothing
end

runit_service 'serf'
