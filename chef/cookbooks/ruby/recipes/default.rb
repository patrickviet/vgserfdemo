execute 'apt-get update' do
  action :nothing
end

package 'python-software-properties'


#execute 'uninstall ruby gems 1.8' do
#  command 'gem1.8 list | cut -d" " -f1 | xargs gem1.8 uninstall -aIx'
#  only_if { File.exists? '/usr/bin/gem1.8' }
#  ignore_failure true
#end

# need this for puppet
#%w[libruby1.8 ruby1.8 ruby1.8-dev rubygem1.8].each do |p|
#  package p do
#    action :remove
#  end
#end

# Ruby 1.9.3p484 from Brightbox
execute 'ppa brighbox ruby' do
  command 'apt-add-repository -y ppa:brightbox/ruby-ng'
  not_if { ::File.exists? '/etc/apt/sources.list.d/brightbox-ruby-ng-precise.list' }
  notifies :run, 'execute[apt-get update]', :immediately
end

%w[ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1 ri1.9.1 build-essential
  libopenssl-ruby1.9.1 libssl-dev zlib1g-dev
].each do |p|
  package p do
    action :upgrade
  end
end

%w[ruby irb gem].each do |name|
  link "/usr/bin/#{name}" do
    user 'root'
    group 'root'
    to name + '1.9.1'
    not_if { File.exists? "/usr/bin/#{name}" and !(File.symlink? "/usr/bin/#{name}") }
  end
end



