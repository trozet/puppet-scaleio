class scaleio::sds (
  $ensure             = 'present',
  $ensure_properties  = 'present',
  $name               = undef,
  $protection_domain  = undef,
  $ips                = undef,
  $ip_roles           = undef,
  $storage_pools      = undef,)
{ 
  
  if $ensure == 'present' {
    $role_opts = $ip_roles ? {undef => '', default => "--sds_ip_role ${ip_roles}" }
    scaleio::cmd {$ensure:
      action => $ensure, entity => 'sds', value => $name, 
      scope_entity => 'protection_domain', scope_value => $protection_domain,
      extra_opts => "--sds_ip ${ips} ${role_opts}"}
  }
  elsif $ensure == 'absent' {
    scaleio::cmd {$ensure:
      action => $ensure, entity => 'sds', value => $name,}
  }
  
  if $ips {
    $ip_array = split($ips, ',')
    
    if $ensure_properties == 'present' {
      $ip_resources = suffix($ip_array, 'i')
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
      $ip_del_resources = suffix($ip_array, 'd')
      scaleio::cmd {$ip_del_resources:
        action => 'remove_sds_ip', ref => 'sds_ip_to_remove', value_in_title => true,
        scope_entity => 'sds', scope_value => $name}  
    }
  }
}
