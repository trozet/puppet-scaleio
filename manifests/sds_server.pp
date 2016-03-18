class scaleio::sds_server (
  $ensure = 'present',
  )
{
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport   => [7072],
    proto  => tcp,
    action => accept,
  }
  package { ['numactl', 'libaio1']:
    ensure => installed,
  } ->
  package { ['emc-scaleio-sds']:
    ensure => $ensure,
  }

  # TODO:
  # "absent" cleanup
}
