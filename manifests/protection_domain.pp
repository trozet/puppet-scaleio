class scaleio::protection_domain (
  $name               = undef,
  $ensure             = 'present',
  $ensure_properties  = 'present',
  $fault_sets         = undef,
  $storage_pools      = undef,)
{  
  scaleio::cmd {$ensure:
    action => $ensure, entity => 'protection_domain', value => $name,}
  if $fault_sets {
    $fs_resources = suffix($fault_sets, '1')
    scaleio::cmd {$fs_resources:
      action => $ensure_properties, entity => 'fault_set', value_in_title => true,
      scope_entity => 'protection_domain', scope_value => $name }     
  }
  if $storage_pools {
    $sp_resources = suffix($storage_pools, '2')
    scaleio::cmd {$sp_resources:
      action => $ensure_properties, entity => 'storage_pool', value_in_title => true,
      scope_entity => 'protection_domain', scope_value => $name }     
  }
}
