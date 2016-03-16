class scaleio::mdm_server (
  $ensure                   = 'present',
  $is_manager               = undef, # 0|1
  $master_mdm_name          = undef,
  $mdm_ips                  = undef, # "1.2.3.4,1.2.3.5"
  $mdm_management_ips       = undef, # "1.2.3.4,1.2.3.5"
  )
{ 
  firewall { '001 Open Ports 6611 and 9011 for ScaleIO MDM':
    dport   => [6611, 9011, 443],
    proto  => tcp,
    action => accept,
  }
  package { ['numactl', 'libaio1', 'mutt', 'python', 'python-paramiko', 'emc-scaleio-mdm' ]:
    ensure => installed,
  }

  if $is_manager != undef
  {
    # Workaround:
    #   Explicitly add the MDM role setting into the config file because
    #   Puppet's installation processes (apt-get/yum)  don't inherit environment variable MDM_ROLE_IS_MANAGER
    #   that is set up during os_prep.pp execution that leads to all MDMs become TB
    file_line { 'mdm role':
      path   => '/opt/emc/scaleio/mdm/cfg/conf.txt',
      line   => "actor_role_is_manager=${is_manager}",
      match  => "^actor_role_is_manager",
      require => Package['emc-scaleio-mdm'],
    } ~>
    service { 'mdm':
      ensure => 'running',
    }
  }

  # Cluster creation is here
  if $master_mdm_name {
    $opts = '--approve_certificate --accept_license --create_mdm_cluster  --use_nonsecure_communication'
    $management_ip_opts = $mdm_management_ips ? {
      undef => '',
      default => "--master_mdm_management_ip ${mdm_management_ips}"}
    exec { 'create cluster':
      command => "scli ${opts} --master_mdm_name ${master_mdm_name} --master_mdm_ip ${mdm_ips} ${management_ip_opts}",
      unless => 'scli --query_cluster --approve_certificate',
      path => '/bin'}
  }

  # TODO:
  # "absent" cleanup
}
