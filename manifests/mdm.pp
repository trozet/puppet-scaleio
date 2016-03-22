define scaleio::mdm (
  $name,
  $ensure                 = 'present',
  $ensure_properties      = 'present',
  $role                   = 'manager',  # manager|tb
  $port                   = undef,
  $ips                    = undef,      # "1.2.3.4,1.2.3.5"
  $management_ips         = undef,      # "1.2.3.4,1.2.3.5"
  )
{
  if $ensure == 'present' {
    $management_ip_opts = $management_ips ? {undef => '', default => "--new_mdm_management_ip ${management_ips}" }
    $port_opts = $port ? {undef => '', default => "--new_mdm_port ${port}" }
    cmd {"${name} ${ensure}":
      action => 'add_standby_mdm', ref => 'new_mdm_name', value => $name,
      scope_ref => 'mdm_role', scope_value => $role,
      extra_opts => "--new_mdm_ip ${ips} ${port_opts} ${management_ip_opts}",
      unless_query => "query_cluster | grep ${name}"}
  }
  elsif $ensure == 'absent' {
    cmd {$ensure:
      action => 'remove_standby_mdm', ref => 'remove_mdm_name', value => $name,}
  }

  if $management_ips {
    cmd {"properties ${name} ${ensure_properties}":
      action => 'modify_management_ip', ref => 'target_mdm_name', value => $name,
      extra_opts => "--new_mdm_management_ip ${management_ips}"}
  }

  # TODO:
  # allow_asymmetric_ips, allow_duplicate_management_ips
}
