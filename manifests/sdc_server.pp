# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure  = 'present',                               # present|absent - Install or remove SDC service
  $mdm_ip  = undef,                                   # string - List of MDM IPs
  $ftp     = 'ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com' # string - FTP with user and password
  )
{
  $ftp_split = split($ftp, '@')
  $ftp_host = $ftp_split[1]
  $ftp_proto_split = split($ftp_split[0], '://')
  $ftp_proto = $ftp_proto_split[0]
  $ftp_creds = split($ftp_proto_split[1], ':')
  notify { "FTP to use for SDC driver: ${ftp}, ${ftp_host}, ${ftp_proto}, ${ftp_creds[0]}, ${ftp_creds[1]}": }
  
  $scini_sync_conf = {
    repo_address        => "${ftp_proto}://${ftp_host}",
    repo_user           => $ftp_creds[0],
    repo_password       => $ftp_creds[1],
    local_dir           => '/bin/emc/scaleio/scini_sync/driver_cache/',
    module_sigcheck     => 1,
    emc_public_gpg_key  => '/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO',
    repo_public_rsa_key => '/bin/emc/scaleio/scini_sync/scini_repo_key.pub',
    sync_pattern        => '.*',
  }
  $scini_sync_keys = keys($scini_sync_conf)

  package { ['numactl', 'libaio1']:
    ensure => installed,
  } ->
  package { ['emc-scaleio-sdc']:
    ensure => $ensure,
  }
  if $ensure == 'present' {
    file { '/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO':
      ensure => present,
      source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      require => Package['emc-scaleio-sdc']
    } ->
    exec { 'scaleio repo public key':
      command => "ssh-keyscan ${ftp_host} | grep ssh-rsa > /bin/emc/scaleio/scini_sync/scini_repo_key.pub",
      path    => ['/bin/', '/usr/bin', '/sbin'],
      require => Package['emc-scaleio-sdc']
    } ->
    scini_sync { $scini_sync_keys:
      config => $scini_sync_conf,
      require => Package['emc-scaleio-sdc']
    } ->
    exec { 'scini sync and update':
      command => 'update_driver_cache.sh && verify_driver.sh',
      unless  => 'verify_driver.sh',
      path    => ['/bin/emc/scaleio/scini_sync/', '/bin/', '/usr/bin', '/sbin'],
      require => Package['emc-scaleio-sdc']
    } ~>
    service { 'scini':
      ensure => running,
      require => Package['emc-scaleio-sdc']
    }
  }
  if $mdm_ip {
    $ip_array = split($mdm_ip, ',')

    if $ensure == 'present' {
        add_ip { $ip_array: }
    }
    file_line { 'Set MDM IP addresses in drv_cfg.txt':
      ensure  => present,
      line    => "mdm ${mdm_ip}",
      path    => '/bin/emc/scaleio/drv_cfg.txt',
      match   => '^mdm .*',
      require => Package['emc-scaleio-sdc'],
    }
  }

  define add_ip {
    exec { "add ip ${title}":
      command  => "drv_cfg --add_mdm --ip ${title}",
      path     => '/opt/emc/scaleio/sdc/bin:/bin',
      require  => Package['emc-scaleio-sdc'],
      unless   => "drv_cfg --query_mdms | grep ${title}"
    }
  }

  define scini_sync($config) {
    file_line { "scini_sync ${title}":
      ensure  => present,
      path    => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
      match   => "^${title}",
      line    => "${title}=${config[$title]}",
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}
