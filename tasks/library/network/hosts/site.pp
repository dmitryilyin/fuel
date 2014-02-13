$fuel_settings = parseyaml($astute_settings_yaml)
$nodes_hash = $::fuel_settings['nodes']

class {"l23network::hosts_file":
  nodes => $nodes_hash,
}