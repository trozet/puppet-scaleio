# SDS configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::sds (
  $name,                            # string - SDS name
  $ensure             = 'present',  # present|absent - Add or remove SDS to cluster
  $ensure_properties  = 'present',  # present|absent - Add or remove SDS properties
  $protection_domain  = undef,      # string - Protection domain to specify when adding to cluster
  $fault_set          = undef,      # string - Fault set
  $port               = undef,      # int - SDS Port
  $ips                = undef,      # string - List of SDS IPs
  $ip_roles           = undef,      # string - List of all|sdc_only|sds_only like 'all,sdc_only,sds_only'
  $storage_pools      = undef,      # string - List of storage pools
  $device_paths       = undef,      # string - List of device paths in the same order as pools above
  )
{
  if $ensure == 'absent' {
    cmd {'$ensure':
      action => $ensure,
      entity => 'sds',
      value  => $name,
    }
  }
  else {
    # TODO:
    # Verify that number of elements in ips with ip_roles and storage_pools with device_paths are equal
    # One storage_pool for all device_paths is not supported
    $role_opts = $ip_roles ? {undef => '', default => "--sds_ip_role ${ip_roles}" }
    $storage_pool_opts = $storage_pools ? {undef => '', default => "--storage_pool_name ${storage_pools}" }
    $device_path_opts = $device_paths ? {undef => '', default => "--device_path ${device_paths}" }
    $fault_set_opts = $fault_set ? {undef => '', default => "--fault_set_name ${fault_set}" }
    $port_opts = $port ? {undef => '', default => "--sds_port ${port}" }
    $sds_resource_title = "SDS ${title} ${ensure}"
    cmd {$sds_resource_title:
      action       => $ensure,
      entity       => 'sds',
      value        => $name,
      scope_entity => 'protection_domain',
      scope_value  => $protection_domain,
      extra_opts   => "--sds_ip ${ips} ${port_opts} ${role_opts} ${storage_pool_opts} ${device_path_opts} ${fault_set_opts}"}

    if $ips {
      $ip_array = split($ips, ',')

      if $ensure_properties == 'present' {
        $ip_resources = suffix($ip_array, ",${name}2")
        cmd {$ip_resources:
          action         => 'add_sds_ip',
          ref            => 'new_sds_ip',
          value_in_title => true,
          scope_entity   => 'sds',
          scope_value    => $name,
          unless_query   => 'query_sds --sds_ip',
          require        => Cmd[$sds_resource_title] }

        if $ip_roles {
          $ips_with_roles = hash(flatten(zip($ip_array, split($ip_roles, ','))))
          $ip_role_resources = suffix($ip_array, ",${name}2")
          $role_existence_string = {'all'=>'All', 'sdc_only'=>'SDC Only', 'sds_only'=>'SDS Only'}
          cmd {$ip_role_resources:
            action                => 'modify_sds_ip_role',
            ref                   => 'sds_ip_to_modify',
            value_in_title        => true,
            scope_entity          => 'sds',
            scope_value           => $name,
            paired_ref            => 'new_sds_ip_role',
            paired_hash           => $ips_with_roles,
            unless_query          => "query_sds --sds_name ${name} | grep",
            unless_query_ext      => ' | grep',
            unless_query_ext_hash => $role_existence_string,
            require               => Cmd[$sds_resource_title] }
        }
      }
      elsif $ensure_properties == 'absent' {
        $ip_del_resources = suffix($ip_array, ",${name}3")
        cmd {$ip_del_resources:
          action          => 'remove_sds_ip',
          ref             => 'sds_ip_to_remove',
          value_in_title  => true,
          scope_entity    => 'sds',
          scope_value     => $name,
          require         => Cmd[$sds_resource_title] }
      }
    }

    if $device_paths {
      $device_array = split($device_paths, ',')

      if $ensure_properties == 'present' {
        $device_resources = suffix($device_array, ",${name}4")
        $devices_with_pools = hash(flatten(zip($device_array, split($storage_pools, ','))))
        cmd {$device_resources:
          action          => 'add_sds_device',
          ref             => 'device_path',
          value_in_title  => true,
          scope_entity    => 'sds',
          scope_value     => $name,
          paired_ref      => 'storage_pool_name',
          paired_hash     => $devices_with_pools,
          unless_query    => "query_sds --sds_name ${name} | grep",
          require         => Cmd[$sds_resource_title] }
      }
      elsif $ensure_properties == 'absent' {
        $device_del_resources = suffix($device_array, ",${name}5")
        cmd {$device_del_resources:
          action          => 'remove_sds_device',
          ref             => 'device_path',
          value_in_title  => true,
          scope_entity    => 'sds',
          scope_value     => $name,
          require         => Cmd[$sds_resource_title] }
      }
    }
  }

  # TODO:
  # rmcache -size/enable/disable
  # num_of_io_buffers
  # port (only one is supported, multiple ports are not planned)
}
