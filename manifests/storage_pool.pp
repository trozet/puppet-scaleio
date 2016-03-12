class scaleio::storage_pool (
  $ensure                         = 'present',
  $name,
  $protection_domain,
  $checksum_mode                  = undef, # enable|disable
  $rmcache_usage                  = undef, # use|dont_use
  $rmcache_write_handling_mode    = undef, # cached|passthrough,
  $rebuild_mode                   = undef, # enable|disable
  $rebalance_mode                 = undef, # enable|disable
  $scanner_mode                   = undef, # device_only|data_comparison|disable
  $scanner_bandwidth_limit        = undef, # int
  $spare_percentage               = undef, # int
  $zero_padding_policy            = undef, # enable|disable
  $rebalance_parallelism_limit    = undef, # int
  )
{
  scaleio::cmd {$ensure:
    action => $ensure, entity => 'storage_pool', value => $name,
    scope_entity => 'protection_domain', scope_value => $protection_domain}
  
  define set($is_defined, $change = ' ')
  {
    if $is_defined {
	    scaleio::cmd {$title:
	      action => $title, ref => "storage_pool_name", value => $scaleio::storage_pool::name,
	      scope_entity => 'protection_domain', scope_value => $scaleio::storage_pool::protection_domain,
	      extra_opts => $change}      
    }
  }
  
  set { 'set_checksum_mode':
    is_defined => $checksum_mode,
    change => "--${checksum_mode}_checksum"}
  
  set { 'set_rebuild_mode':
    is_defined => $rebuild_mode,
    change => "--${rebuild_mode}_rebuild --i_am_sure"}
  
  set { 'set_rebalance_mode':
    is_defined => $rebalance_mode,
    change => "--${rebalance_mode}_rebalance --i_am_sure"}
  
  set { 'modify_zero_padding_policy':
    is_defined => $zero_padding_policy,
    change => "--${zero_padding_policy}_zero_padding"}
  
  set { 'set_rmcache_write_handling_mode':
    is_defined => $rmcache_write_handling_mode,
    change => "--rmcache_write_handling_mode ${rmcache_write_handling_mode} --i_am_sure"}
  
  set { 'set_rmcache_usage':
    is_defined => $rmcache_usage,
    change => "--${rmcache_usage}_rmcache --i_am_sure"}
    
  set { 'modify_spare_policy':
    is_defined => $spare_percentage,
    change => "--spare_percentage ${spare_percentage} --i_am_sure"}
    
  set { 'set_rebuild_rebalance_parallelism':
    is_defined => $rebalance_parallelism_limit,
    change => "--limit ${rebalance_parallelism_limit}"}
    
  if $scanner_mode {
    if $scanner_mode == 'disable' {
		  set { 'disable_background_device_scanner': 
		    is_defined => true}  
		}
		else {
		  set { 'enable_background_device_scanner': 
		    is_defined => true,
		    change => "--scanner_mode ${scanner_mode} --scanner_bandwidth_limit ${scanner_bandwidth_limit}"}		  
		}
	}

  # TODO:
  # Rebuild and rebalance policy should be done in separate manifest - too many options and values
}
