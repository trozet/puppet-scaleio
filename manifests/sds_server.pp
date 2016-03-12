class scaleio::sds_server (
  $ensure = 'present',
  )
{ 
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport   => [7072],
    proto  => tcp,
    action => accept,
  }
  package { ['numactl', 'libaio1' ]:
    ensure => installed,
  } ->
  package { 'emc-scaleio-sds':
    provider  => dpkg,
    source    => '/home/alevine/shared/EMC-ScaleIO-sds-2.0-5014.0.Ubuntu.14.04.x86_64.deb',
    ensure    => $ensure,
  }
}
