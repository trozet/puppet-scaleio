define scaleio::protection_domain (
  $name,
  $ensure             = 'present',
  $ensure_properties  = 'present',
  $fault_sets         = undef,      # ['fs1','fs2']
  $storage_pools      = undef,      # ['sp1','sp2']
  )
{
  $fs_resources = suffix($fault_sets, '1')
  $sp_resources = suffix($storage_pools, '2')
  Cmd[$ensure]->Cmd[$fs_resources]->Cmd[$sp_resources]
  cmd {$ensure:
    action => $ensure, entity => 'protection_domain', value => $name,}
  if $fault_sets {
    cmd {$fs_resources:
      action => $ensure_properties, entity => 'fault_set', value_in_title => true,
      scope_entity => 'protection_domain', scope_value => $name }
  }
  if $storage_pools {
    cmd {$sp_resources:
      action => $ensure_properties, entity => 'storage_pool', value_in_title => true,
      scope_entity => 'protection_domain', scope_value => $name }
  }

  # TODO:
  # set_sds_network_limits
}
