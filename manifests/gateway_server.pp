class scaleio::gateway_server (
  $ensure       = 'present',
  $mdm_ips      = undef, # "1.2.3.4,1.2.3.5"
  $password     = undef,
  $port         = 4443,
  )
{
  if $ensure == 'absent'
  {
    package { 'emc-scaleio-gateway':
      ensure    => 'purged',
      provider  => dpkg,
    }
  }
  else {
    Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
    firewall { '001 for ScaleIO Gateway':
      dport  => [$port],
      proto  => tcp,
      action => accept,
    }
    package { ['numactl', 'libaio1']:
        ensure  => installed,
    } ->
    # Below are a java 1.8 installation steps which shouldn't be required for newer Ubuntu versions
    exec { 'add java8 repo':
      unless  => 'apt-cache search oracle-java8-installer || grep "webupd8team/java" /etc/apt/sources.list /etc/apt/sources.list.d/*',
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
    } ->
    file_line { 'Set security bypass':
      ensure  => present,
      line    => "security.bypass_certificate_check=true",
      path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
      match   => '^security.bypass_certificate_check=',
      require => Package['emc-scaleio-gateway'],
    } ->
    file_line { 'Set gateway port':
      ensure  => present,
      line    => "ssl.port={$port}",
      path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match   => "^ssl.port=",
      require => Package['emc-scaleio-gateway'],
    } ~>
    service { 'scaleio-gateway':
      ensure  => 'running',
      enable  => true,
    }
    if $mdm_ip {
      $mdm_ips_str = join(split($mdm_ips,','), ';')
      file_line { 'Set MDM IP addresses':
        ensure  => present,
        line    => "mdm.ip.addresses={$mdm_ips_str}",
        path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
        match   => '^mdm.ip.addresses=.*',
        require => Package['emc-scaleio-gateway'],
      }
    }
    if $password {
      exec { 'Set gateway admin password':
        command => "java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar --reset_password '${password}' --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties",
        path => '/etc/alternatives',
        refreshonly => true,
        notify => Service['scaleio-gateway']
      }
    }
  }

  # TODO:
  # "absent" cleanup
  # try installing java by puppet install module puppetlabs-java
}
