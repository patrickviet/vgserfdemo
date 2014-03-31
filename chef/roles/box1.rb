default_attributes(
  'nerve' => { 'enabled_services' => [ 'sqlslave' ] },
)

run_list(
  'serf', 'ruby','mysql', 'smartstack::nerve'
)
