class scaleio::sds_server (
  $ensure = 'present',
  )
{
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport   => [7072],
    proto  => tcp,
    action => accept,
  }
  package { ['numactl', 'libaio1', 'emc-scaleio-sds' ]:
    ensure => installed,
  }

  # TODO:
  # "absent" cleanup
}
