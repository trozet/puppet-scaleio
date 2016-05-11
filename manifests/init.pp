# == Class: scaleio
#
# Deploys ScaleIO cluster.
#
# This class contains common resources

class scaleio {
  package { 'numactl':
      ensure => installed,
  }

  $libaio_package = $::osfamily ? {
      'RedHat' => 'libaio',
      'Debian' => 'libaio1',
  }

  package { $libaio_package:
    ensure => installed,
  }
}
