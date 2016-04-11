# Configure ScaleIO SDS service installation

class scaleio::sds_server (
  $ensure = 'present',  # present|absent - Install or remove SDS service
  )
{
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport  => [7072],
    proto  => tcp,
    action => accept,
  }
  package { ['numactl', 'libaio1']:
    ensure => installed,
  } ->
  package { ['emc-scaleio-sds']:
    ensure => $ensure,
  } ->
  exec { 'Apply noop IO scheduler for SSD/flash disks':
    command   => 'bash -c \'for i in `lsblk -d -o ROTA,KNAME | awk "/^ *0/ {print($2)}"` ; do if [ -f /sys/block/$i/queue/scheduler ]; then echo noop > /sys/block/$i/queue/scheduler; fi; done\'',
    path      => '/bin:/usr/bin',
  }
  
  
  # TODO:
  # "absent" cleanup
}
