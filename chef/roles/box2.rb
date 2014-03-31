default_attributes(
  'synapse' => { 'enabled_services' => [ 'sqlslave' ] },
)

run_list(
  'serf', 'ruby','smartstack::synapse'
)
