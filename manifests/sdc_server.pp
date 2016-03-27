# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure  = 'present', # present|absent - Install or remove SDC service
  $mdm_ip  = undef,     # string - List of MDM IPs
  )
{
  package { ['numactl', 'libaio1']:
    ensure => installed,
  } ->
  package { ['emc-scaleio-sdc']:
    ensure => $ensure,
  }
  if $mdm_ip {
    exec { 'connect to mdm':
      command => "drv_cfg --add_mdm --ip ${mdm_ip}",
      path => '/opt/emc/scaleio/sdc/bin:/bin',
      require => Package['emc-scaleio-sdc'],
      onlyif => "drv_cfg --query_mdms | grep 'Retrieved 0'"
    } ->
    file_line { 'Set MDM IP addresses in drv_cfg.txt':
      ensure  => present,
      line    => "mdm ${mdm_ip}",
      path    => '/bin/emc/scaleio/drv_cfg.txt',
      match   => '^mdm .*',
      require => Package['emc-scaleio-sdc'],
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}
