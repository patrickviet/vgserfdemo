chef_dir =    "/vagrant/chef"
cookbook_path "#{chef_dir}/cookbooks"
role_path     "#{chef_dir}/roles"
data_bag_path "#{chef_dir}/data_bags"

log_level        :info
log_location     STDOUT
