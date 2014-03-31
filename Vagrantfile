# -*- mode: ruby -*-
# vi: set ft=ruby :

this_dir = File.dirname(File.expand_path __FILE__)
chef_secret = File.join(ENV['HOME'], "/.ssh/encrypted_data_bag_secret")

Vagrant.configure("2") do |config|

  %w[box1 box2].each_with_index do |name,num|
    config.vm.define "#{name}" do |box|
      config.vm.provision "shell", path: "provision.sh", args: name
      box.vm.network :private_network, ip: "192.168.33.1#{num}"
    end
  end

  config.vm.box = "webmonarch/precise64"
end
