include_attribute 'smartstack::ports'

# on chef-solo < 11.6, we hack around lack of environment support
# by using node.env because node.environment cannot be set
default.smartstack.env = (node.has_key?('env') ? node.env : node.environment)

default.smartstack.services = {
  'synapse' => {},
  'nerve'   => {},
  'haproxy' => {},

  'memcache' => {
    'synapse' => {
      'discovery' => { 'method' => 'serf' },
      'haproxy' => {
        'server_options' => 'check inter 1s rise 1 fall 1',
        'listen' => [
          'mode tcp',
        ],
      },
    },
    'nerve' => {
      'port' => 11211,
      'check_interval' => 1,
      'reporter_type' => 'serf',
      'checks' => [
        { 'type' => 'tcp', 'timeout' => 1, 'rise' => 2, 'fall' => 3 },
      ],
    },
  },

  'elasticsearch' => {
    'synapse' => {
      'discovery' => { 'method' => 'serf' },
      'haproxy' => {
        'server_options' => 'check inter 5s fastinter 2s downinter 3s rise 3 fall 2',
        'listen' => [ 'mode http', 'option httpchk GET /', ],
      },
    },
    'nerve' => {
      'port' => 9200,
      'check_interval' => 3,
      'reporter_type' => 'serf',
      'checks' => [
        { 'type' => 'http', 'uri' => '/_cluster/health', 'timeout' => 1, 'rise' => 2, 'fall' => 2 },
      ],
    },
  },

  'sqlslave' => {
    'synapse' => {
      'discovery' => { 'method' => 'serf' },
      'haproxy' => {
        'server_options' => 'check inter 10s fastinter 5s downinter 8s rise 3 fall 2',
        'listen' => [
          'mode tcp',
          'timeout  connect 10s',
          'timeout  client  1h',
          'timeout  server  1h',
        ],
      },
    },
    'nerve' => {
      'port' => 3306,
      'check_interval' => 3,
      'reporter_type' => 'serf',
      'checks' => [
        { 'type' => 'tcp', 'timeout' => 5, 'rise' => 2, 'fall' => 2 },
      ],
    },
  },

}

# make sure each service has a smartstack config
default.smartstack.services.each do |name, service|
  # populate zk paths for all services
  unless service.has_key? 'zk_path'
    default.smartstack.services[name]['zk_path'] = "/#{node.smartstack.env}/services/#{name}/services"
  end

  # populate the local_port for all services
  port = node.smartstack.service_ports[name]
  if Integer === port
    service['local_port'] = port
  else
    Chef::Log.error "Service #{name} has no synapse port allocated; please see services/attributes/ports.rb"
    raise "Synapse port missing for #{name}"
  end
end
