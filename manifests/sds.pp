class scaleio::sds (
  $ensure             = 'present',
  $ensure_properties  = 'present',
  $name               = undef,
  $protection_domain  = undef,
  $fault_set          = undef,
  $ips                = undef,
  $ip_roles           = undef,
  $storage_pools      = undef,
  $device_paths       = undef)
{ 
  
  if $ensure == 'present' {
    # TODO:
    # Verify that number of elements in ips with ip_roles and storage_pools with device_paths are equal
    # One storage_pool for all device_paths is not supported
    $role_opts = $ip_roles ? {undef => '', default => "--sds_ip_role ${ip_roles}" }
    $storage_pool_opts = $storage_pools ? {undef => '', default => "--storage_pool ${storage_pools}" }
    $device_path_opts = $device_paths ? {undef => '', default => "--device_path ${device_paths}" }
    $fault_set_opts = $fault_set ? {undef => '', default => "--fault_set_name ${fault_set}" }
    scaleio::cmd {$ensure:
      action => $ensure, entity => 'sds', value => $name, 
      scope_entity => 'protection_domain', scope_value => $protection_domain,
      extra_opts => "--sds_ip ${ips} ${role_opts} ${storage_pool_opts} ${device_path_opts} ${fault_set_opts}"}
  }
  elsif $ensure == 'absent' {
    scaleio::cmd {$ensure:
      action => $ensure, entity => 'sds', value => $name,}
  }
  
  if $ips {
    $ip_array = split($ips, ',')
    
    if $ensure_properties == 'present' {
      $ip_resources = suffix($ip_array, '1')
      scaleio::cmd {$ip_resources:
        action => 'add_sds_ip', ref => 'new_sds_ip', value_in_title => true,
        scope_entity => 'sds', scope_value => $name,
        unless_query => 'query_sds --sds_ip'}  
        
      if $ip_roles {
        $ips_with_roles = hash(flatten(zip($ip_array, split($ip_roles, ','))))
        $ip_role_resources = suffix($ip_array, 'r')
        scaleio::cmd {$ip_role_resources:
          action => 'modify_sds_ip_role', ref => 'sds_ip_to_modify', value_in_title => true,
          scope_entity => 'sds', scope_value => $name,
          paired_ref => "new_sds_ip_role", paired_hash => $ips_with_roles} 
      }
    }   
    elsif $ensure_properties == 'absent' {
      $ip_del_resources = suffix($ip_array, '2')
      scaleio::cmd {$ip_del_resources:
        action => 'remove_sds_ip', ref => 'sds_ip_to_remove', value_in_title => true,
        scope_entity => 'sds', scope_value => $name}  
    }
  }

  if $device_paths {
    $device_array = split($device_paths, ',')
    
    if $ensure_properties == 'present' {
      $device_resources = suffix($device_array, '3')
      $devices_with_pools = hash(flatten(zip($device_array, split($storage_pools, ','))))
      scaleio::cmd {$device_resources:
        action => 'add_sds_device', ref => 'device_path', value_in_title => true,
        scope_entity => 'sds', scope_value => $name,
        paired_ref => 'storage_pool_name', paired_hash => $devices_with_pools,
        unless_query => "query_sds --sds_name ${name} | grep"}          
    }   
    elsif $ensure_properties == 'absent' {
      $device_del_resources = suffix($device_array, '4')
      scaleio::cmd {$device_del_resources:
        action => 'remove_sds_device', ref => 'device_path', value_in_title => true,
        scope_entity => 'sds', scope_value => $name}  
    }
  }

  # TODO:
  # rmcache -size/enable/disable
  # num_of_io_buffers
  # port (only one, multiple ports are not planned)
}
