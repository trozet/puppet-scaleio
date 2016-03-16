class scaleio::sdc_server (
  $ensure  = 'present',
  $mdm_ip  = undef,
  )
{
  package { ['numactl', 'libaio1', 'emc-scaleio-sdc' ]:
    ensure => installed,
  }
  if $mdm_ip {
    exec { 'connect to mdm':
      command => "drv_cfg --add_mdm --ip ${mdm_ip}",
      path => '/opt/emc/scaleio/sdc/bin',
      require => Package['emc-scaleio-sdc']}
  }

  # TODO:
  # "absent" cleanup
}
