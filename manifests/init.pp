# == Class: scaleio
#
# Full description of class scaleio here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { scaleio:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class scaleio {

  define cluster (
	  $ensure                       = 'present', 
	  $cluster_mode                 = undef, # 1|3|5
	  $slave_names                  = undef, # "mdm1,mdm2"
	  $tb_names                     = undef, # "tb1,tb2"
	  $password                     = undef,
	  $new_password                 = undef,
	  $restricted_sdc_mode          = undef, # enabled|disabled
	  $license_file_path            = undef,
	  $remote_readonly_limit_state  = undef, # enabled|disabled
  )
  {
    class { 'scaleio::cluster': 
      ensure=>$ensure, cluster_mode=>$cluster_mode,
      slave_names=>$slave_names, tb_names=>$tb_names,
      password=>$password, new_password=>$new_password,
      restricted_sdc_mode=>$restricted_sdc_mode,
      license_file_path=>$license_file_path,
      remote_readonly_limit_state=>$remote_readonly_limit_state,
    }    
  }
  
  define mdm (
	  $ensure                 = 'present',
	  $ensure_properties      = 'present',
	  $name,
	  $role                   = 'manager',  # manager|tb
	  $port                   = undef,
	  $ips                    = undef,      # "1.2.3.4,1.2.3.5"
	  $management_ips         = undef,      # "1.2.3.4,1.2.3.5"
  )
  {
    class { 'scaleio::mdm': 
      ensure=>$ensure, ensure_properties=>$ensure_properties, name=>$name,
      role=>$role, port=>$port, ips=>$ips, management_ips=>$management_ips,
    }
  }

  define sds (
	  $ensure             = 'present',
	  $ensure_properties  = 'present',
	  $name,
	  $protection_domain  = undef,
	  $fault_set          = undef,
	  $port               = undef,
	  $ips                = undef, # "1.2.3.4,1.2.3.5"
	  $ip_roles           = undef, # "all,all"
	  $storage_pools      = undef, # "sp1,sp2"
	  $device_paths       = undef, # "/dev/sdb,/dev/sdc"
  )
  {
    class { 'scaleio::sds':
      ensure=>$ensure, ensure_properties=>$ensure_properties, name=>$name,
      protection_domain=>$protection_domain, fault_set=>$fault_set, port=>$port,
      ips=>$ips, ip_roles=>$ip_roles, storage_pools=>$storage_pools, device_paths=>$device_paths,
    }
  }

  define sdc (
    $ensure = 'present',
    $ip,
  )
  {
    class { 'scaleio::sdc':
      ensure=>$ensure, ip=>$ip,
    }
  }

  define protection_domain (
	  $ensure             = 'present',
	  $ensure_properties  = 'present',
    $name,
	  $fault_sets         = undef,
	  $storage_pools      = undef,
  )
  {
    class { 'scaleio::protection_domain':
      ensure=>$ensure, ensure_properties=>$ensure_properties, name=>$name,
      fault_sets=>$fault_sets, storage_pools=>$storage_pools,
    }
  }

  define storage_pool (
	  $ensure                         = 'present',
	  $name,
	  $protection_domain,
	  $checksum_mode                  = undef, # enable|disable
	  $rmcache_usage                  = undef, # use|dont_use
	  $rmcache_write_handling_mode    = undef, # cached|passthrough,
	  $rebuild_mode                   = undef, # enable|disable
	  $rebalance_mode                 = undef, # enable|disable
	  $scanner_mode                   = '',    # device_only|data_comparison|disable
	  $scanner_bandwidth_limit        = undef, # int
	  $spare_percentage               = undef, # int
	  $zero_padding_policy            = undef, # enable|disable
	  $rebalance_parallelism_limit    = undef, # int
  )
  {
    class { 'scaleio::storage_pool':
      ensure=>$ensure, name=>$name,
      protection_domain=>$protection_domain, checksum_mode=>$checksum_mode,
      rmcache_usage=>$rmcache_usage, rmcache_write_handling_mode=>$rmcache_write_handling_mode,
      rebuild_mode=>$rebuild_mode, rebalance_mode=>$rebalance_mode,
      scanner_mode=>$scanner_mode, scanner_bandwidth_limit=>$scanner_bandwidth_limit,
      spare_percentage=>$spare_percentage, zero_padding_policy=>$zero_padding_policy,
      rebalance_parallelism_limit=>$rebalance_parallelism_limit,
    }    
  }

  define login($password)
  {
    scaleio::scli::cmd { 'login':
      action=>'login', ref=>'password', value=>$password,
      scope_ref=>'username', scope_value=>'admin'
    }
  }

  # TODO:
  # Comments and headers everywhere
}
