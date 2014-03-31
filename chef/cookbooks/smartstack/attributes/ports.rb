default.smartstack.ports = {
  # reserved for health checks on synapse itself
  # TODO: implement health checks on synapse
  3210 => 'synapse',
  # reserved for a possible UI for nerve
  3211 => 'nerve',
  # reserved for the haproxy stats socket
  3212 => 'haproxy',

  # moar services
  3306 => 'mysql',

  3401 => 'memcache',
  3402 => 'sqlslave',
  3403 => 'elasticsearch',
}

# also create a mapping going the other way
default.smartstack.service_ports = Hash[node.smartstack.ports.collect {|k, v| [v, k]}]
