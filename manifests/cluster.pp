# Configure ScaleIO cluster nodes, and cluster parameters.
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::cluster (
  $ensure                       = 'present',  # present|absent - Create or destroy cluster
  $cluster_mode                 = undef,      # 1|3|5 - Cluster mode
  $slave_names                  = undef,      # string - List of MDM slaves to add or remove
  $tb_names                     = undef,      # s - List of tiebreakers to add or remove
  $password                     = undef,      # string - Current password
  $new_password                 = undef,      # string - New password
  $restricted_sdc_mode          = undef,      # 'enabled'|'disabled' - Restricted SDC mode
  $license_file_path            = undef,      # string - Path to license file
  $remote_readonly_limit_state  = undef,      # 'enabled'|'disabled' - Remote readonly limit state
  )
{
  if $cluster_mode {
    # Cluster mode changed
    $action = $ensure ? {'absent' => 'remove', default => 'add'}
    cmd {"switch cluster mode ${cluster_mode}, action: ${action}, slaves: ${slave_names}, tbs: ${tb_names}":
      action        => 'switch_cluster_mode',
      ref           => 'cluster_mode',
      value         => "${cluster_mode}_node",
      extra_opts    => "--${action}_slave_mdm_name ${slave_names} --${action}_tb_name ${tb_names} --i_am_sure",
      unless_query  => 'query_cluster | grep -A 1 "Cluster:" | grep'
    }
  }
  if $new_password {
    cmd {'set password':
      action              => 'set_password',
      ref                 => 'new_password',
      value               => $new_password,
      scope_ref           => 'old_password',
      scope_value         => $password,
      approve_certificate => ''
    }
  }
  if $restricted_sdc_mode {
    cmd {'set restricted sdc mode':
      action  => 'set_restricted_sdc_mode',
      ref     => 'restricted_sdc_mode',
      value   => $restricted_sdc_mode}
  }
  if $license_file_path {
    cmd {'set license':
      action => 'set_license',
      ref    => 'license_file',
      value  => $license_file_path}
  }
  if $remote_readonly_limit_state {
    cmd {'set remote readonly limit state':
      action => 'set',
      entity => 'remote_readonly_limit_state',
      value  => $remote_readonly_limit_state}
  }

  # TODO:
  # Replace cluster mdm
  # Users, Volumes, Certificates, Caches
  # Password can be changed only with current password - can be done by resetting with only new password
}
