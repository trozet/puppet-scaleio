# SDC configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::sdc (
  $ip,                  # string - IP to specify SDC in cluster
  $ensure = 'present',  # present|absent - 'absent' removes SDC from cluster
  )
{
  if $ensure == 'absent' {
    cmd {$ensure:
      action      => 'remove_sdc',
      ref         => 'sdc_ip',
      value       => $ip,
      extra_opts  => '--i_am_sure'}
  }
}
