define scaleio::sdc (
  $ip,
  $ensure = 'present',
  )
{
  if $ensure == 'absent' {
    cmd {$ensure:
      action => 'remove_sdc', ref => 'sdc_ip', value => $ip,}
  }
}
