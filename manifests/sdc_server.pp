class scaleio::sdc_server (
  $ensure  = 'present',
  $mdm_ip  = undef,
  )
{ 
  package { ['numactl', 'libaio1' ]:
    ensure => installed,
  } ->
  package { 'emc-scaleio-sdc':
    provider  => dpkg,
    source    => '/home/alevine/shared/EMC-ScaleIO-sdc-2.0-5014.0.Ubuntu.14.04.x86_64.deb',
    ensure    => $ensure,
  }
  if $mdm_ip {
    exec { 'connect to mdm':
      command => "drv_cfg --add_mdm --ip ${mdm_ip}",
      path => '/opt/emc/scaleio/sdc/bin',
      require => Package['emc-scaleio-sdc']}
  }
}
