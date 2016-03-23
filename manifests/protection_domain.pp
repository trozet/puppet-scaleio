define scaleio::protection_domain (
  $name,
  $ensure             = 'present',
  $ensure_properties  = 'present',
  $fault_sets         = undef,
  $storage_pools      = undef,
  )
{
  cmd {"Protection domain ${title} ${ensure}":
    action => $ensure, entity => 'protection_domain', value => $name,}
  if $fault_sets {
    $fs_resources = suffix($fault_sets, '1')
    cmd {$fs_resources:
      action => $ensure_properties, entity => 'fault_set', value_in_title => true,
      scope_entity => 'protection_domain', scope_value => $name,
      require => Cmd['$ensure'],
    }
  }
  if $storage_pools {
    $sp_resources = suffix($storage_pools, '2')
    cmd {$sp_resources:
      action => $ensure_properties, entity => 'storage_pool', value_in_title => true,
      scope_entity => 'protection_domain', scope_value => $name,
      require => Cmd['$ensure'],
    }
  }

  # TODO:
  # set_sds_network_limits
}
