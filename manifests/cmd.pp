# == Class: scli
#
# Full description of class scli here.
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

# Logic compiling scli command from parameters and invoking it.
# For actions "add" checks with "query" in unless if such entity exists.
# Accepts actions "present" and "absent" instead of "add" and "remove".
# Supports calling with arrays for values, in which case $value shouldn't
# be used, instead $value_in_title flag should be set.
# facter mdm_ips variable should be set to "ip1,ip2,...".
define cmd(
  $action,
  $entity = undef,
  $ref = 'name',
  $value = undef,
  $scope_entity = undef,
  $scope_ref = 'name',
  $scope_value = undef,
  $value_in_title = undef,
  $paired_ref = undef,
  $paired_hash = {},
  $extra_opts = '',
  $unless_query = undef,
  $approve_certificate = '--approve_certificate',)
{
  # Command
  $cmd = $action ? {
    'present' => 'add',
    'absent' => 'remove',
    default => $action}
  $cmd_opt = $entity ? {
    undef =>  "--${cmd}",
    default => "--${cmd}_${entity}"}
  # Taking title for value for array values. Chop is used to extract ips from resources
  # because one different extra character per call allows to differentiate them.
  $val = $value_in_title ? {
    undef => $value,
    default => chop($title)}
  # Main object parts
  $obj_ref = $entity ? {
    undef =>  "--${ref}",
    default => "--${entity}_${ref}"}
  $obj_ref_opt = $val ? {
    undef => '',
    default => "${obj_ref} ${val}"}
  # Scope object parts (e.g. protection_domain for fault_sets)
  $scope_obj_ref = $scope_entity ? {
    undef =>  "--${scope_ref}",
    default => "--${scope_entity}_${scope_ref}"}
  $scope_obj_ref_opt = $scope_value ? {
    undef => '',
    default => "${scope_obj_ref} ${scope_value}"}
  # Paired values for arrays of pairs (e.g., ips and roles for SDS)
  $paired_obj_value = $paired_hash[chop($title)]
  $paired_obj_ref_opt = $paired_obj_value ? {
    undef => '',
    default => "--${paired_ref} ${paired_obj_value}"}

  $mdm_opts = $::mdm_ips ? {
    undef => '',
    default => "--mdm_ip ${::mdm_ips}"}
  $command = "scli ${mdm_opts} ${approve_certificate} ${cmd_opt} ${obj_ref_opt} ${scope_obj_ref_opt} ${paired_obj_ref_opt} ${extra_opts}"
  $unless_cmd = $cmd ? {
    'add' => "scli ${mdm_opts} ${approve_certificate}  --query_${entity} ${obj_ref_opt} ${scope_obj_ref_opt}",
    default => undef}
  # Custom unless query for addition is set - will check existense of the val to be added
  $unless_command = $unless_query ? {
    undef => $unless_cmd,
    default => "scli ${mdm_opts} ${approve_certificate}  --${unless_query} ${val}"}

  notify { "SCLI COMMAND: ${command}": }
  if $unless_command {
    notify { "SCLI UNLESS: ${unless_command}": }
  }
  exec { $command:
    command => $command,
    path => ['/bin/'],
    unless => $unless_command,
  }
}


