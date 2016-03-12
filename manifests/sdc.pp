class scaleio::sdc (
  $ip,
  $ensure = 'present',
  )
{ 
  if $ensure == 'absent' { 
    scaleio::cmd {$ensure:
      action => 'remove_sdc', ref => 'sdc_ip', value => $ip,}
  }
}
