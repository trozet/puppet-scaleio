class scaleio::mdm_server (
  $ensure                   = 'present',
  $is_manager               = undef,          # 0|1
  $master_mdm_name          = undef,
  $mdm_ips                  = undef,      # "1.2.3.4,1.2.3.5"
  $mdm_management_ips       = undef,      # "1.2.3.4,1.2.3.5"
  )
{
  if $ensure == 'absent' {
    package { ['emc-scaleio-mdm']:
      ensure => 'absent',
    }
  }
  else {
    firewall { '001 Open Ports 6611 and 9011 for ScaleIO MDM':
      dport   => [6611, 9011, 443],
      proto  => tcp,
      action => accept,
    }
    package { ['numactl', 'libaio1', 'mutt', 'python', 'python-paramiko']:
      ensure => installed,
    } ->
    package { ['emc-scaleio-mdm']:
      ensure => $ensure,
    }
    service { ['mdm']:
      ensure => 'running',
      enable => 'true',
      hasstatus => 'true',
      require => Package['emc-scaleio-mdm'],
    }

    if $is_manager != undef {
      # Workaround:
      #   Explicitly add the MDM role setting into the config file because
      #   Puppet's installation processes (apt-get/yum)  don't inherit environment variable MDM_ROLE_IS_MANAGER
      #   that is set up during os_prep.pp execution that leads to all MDMs become TB
      file_line { 'mdm role':
        path   => '/opt/emc/scaleio/mdm/cfg/conf.txt',
        line   => "actor_role_is_manager=${is_manager}",
        match  => "^actor_role_is_manager",
        notify => Service['mdm'],
        before => [Exec['create_cluster']],
      }
    }

    # Cluster creation is here
    $opts = '--approve_certificate --accept_license --create_mdm_cluster --use_nonsecure_communication'
    $management_ip_opts = $mdm_management_ips ? {
      undef => '',
      default => "--master_mdm_management_ip ${mdm_management_ips}"
    }
    exec { 'create_cluster':
      onlyif => "test -n '${master_mdm_name}'",
      require => Service['mdm'],
      # sleep is needed here because service in role changing can be still alive and not restarted
      command => "sleep 2 ; scli --query_cluster --approve_certificate || scli ${opts} --master_mdm_name ${master_mdm_name} --master_mdm_ip ${mdm_ips} ${management_ip_opts}",
      path => '/bin:/usr/bin',
      tries => 5,
      try_sleep => 5,
    }
  }

  # TODO:
  # "absent" cleanup
}
