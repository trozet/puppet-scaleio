define scaleio::cluster (
  $ensure                       = 'present', 
  $cluster_mode                 = undef, # 1|3|5
  $slave_names                  = undef, # "mdm1,mdm2"
  $tb_names                     = undef, # "tb1,tb2"
  $password                     = undef,
  $new_password                 = undef,
  $restricted_sdc_mode          = undef, # enabled|disabled
  $license_file_path            = undef,
  $remote_readonly_limit_state  = undef, # enabled|disabled
  )
{ 
  if $cluster_mode {
    $action = $ensure ? {'absent' => 'remove', default => 'add'}
    cmd {'switch cluster mode':
      action => 'switch_cluster_mode', ref => 'cluster_mode', value => "${cluster_mode}_node",
      extra_opts => "--${action}_slave_mdm_name ${slave_names} --${action}_tb_name ${tb_names} --i_am_sure"}   
  }  
  if $new_password {
    cmd {'set password':
      action => 'set_password', ref => 'new_password', value => $new_password,
      scope_ref => 'old_password', scope_value => $password}
  }
  if $restricted_sdc_mode {
    cmd {'set restricted sdc mode':
      action => 'set_restricted_sdc_mode', ref => 'restricted_sdc_mode', value => $restricted_sdc_mode}
  }
  if $license_file_path {
    cmd {'set license':
      action => 'set_license', ref => 'license_file', value => $license_file_path}
  }
  if $remote_readonly_limit_state {
    cmd {'set remote readonly limit state':
      action => 'set', entity => 'remote_readonly_limit_state', value => $remote_readonly_limit_state}
  }
  
  # TODO:
  # Replace cluster mdm
  # Users, Volumes, Certificates, Caches
}
