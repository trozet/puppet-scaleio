class scaleio::gateway_server (
  $ensure       = 'present',
  $mdm_ips      = undef, # "1.2.3.4,1.2.3.5"
  $password     = undef,
  )
{
  if $ensure == 'absent'
  {
    package { 'emc-scaleio-gateway':
      provider  => dpkg,
      ensure    => 'purged'}
  }
  else {
    Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
    firewall { '001 for ScaleIO Gateway':
      dport  => [443],
      proto  => tcp,
      action => accept,
    }
    package { ['numactl', 'libaio1']:
        ensure  => installed,
    } ->
    # Below are a java 1.8 installation steps which shouldn't be required for newer Ubuntu versions
    exec { 'add java8 repo':
      command => 'add-apt-repository ppa:webupd8team/java && apt-get update',
    } ->
    exec { 'java license accepting step 1':
      command => 'echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections',
    } ->
    exec { 'java license accepting step 2':
      command => 'echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections',
    } ->
    package { 'oracle-java8-installer':
        ensure  => installed,
    } ->
    package { 'emc-scaleio-gateway':
        ensure  => installed,
    }
    service { 'scaleio-gateway':
      ensure  => 'running',
      enable  => true,
    }
    if $mdm_ip {
      $mdm_ips_str = join(split($mdm_ips,','), ';')
      file_line { 'Set MDM IP addresses':
        ensure  => present,
        line    => "mdm.ip.addresses=",
        path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
        match   => '^mdm.ip.addresses=.*',
        require => Package['emc-scaleio-gateway'],
      }
    }
    if $password {
      exec { 'Set gateway admin password':
        command => "java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar --reset_password '${password}' --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties",
        path => "/etc/alternatives",
        refreshonly => true,
        notify => Service['scaleio-gateway']
      }
    }
  }

  # TODO:
  # "absent" cleanup
  # try installing java by puppet install module puppetlabs-java
}
