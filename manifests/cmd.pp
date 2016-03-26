# Logic compiling scli command from parameters and invoking it.
# For actions "add" checks with "query" in unless if such entity exists.
# Accepts actions "present" and "absent" instead of "add" and "remove".
# Supports calling with arrays for values, in which case $value shouldn't
# be used, instead $value_in_title flag should be set.
# facter mdm_ips variable should be set to "ip1,ip2,...".

define cmd(
  $action,                  # Action like present|absent|add|remove|add_sds|... if entity specified it's added to --action_entity
  $entity = undef,          # Entity for the action like --action_entity --entity_name
  $ref = 'name',            # Type of the reference for entity like --entity_ref or full reference if entity omitted.
  $value = undef,           # Value - Value for the entity like --action_entity --entity_ref value, or --action --ref value
  $scope_entity = undef,    # Scope Entity - Scope for the Entity like Protection domain for Storage pools - same rules as above.
  $scope_ref = 'name',      # Scope reference
  $scope_value = undef,     # Scope Value
  $value_in_title = undef,  # Flag to use value from $title - pass it with true for this instead of $value
  $paired_ref = undef,      # For arrays of titles used as a ref for value in paired_hash like for --new_sds_ip_role
  $paired_hash = {},        # Hash of values for arrays of titles
  $extra_opts = '',         # String with any extra options like '--i_am_sure'
  $unless_query = undef,    # Explicit unless like "query_sds --sds_name ${name} | grep" without value at the end or implicit for add commands
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
  # Taking title for value for array values. Split is used to extract ips from resources
  # because one different extra character per call allows to differentiate them.
  # In case of title parameters look like 'parameter,suffix", suffix is just for 
  # avoiding resource duplication.
  if $value_in_title {
    $val_ = split($title, ',')
    $val = $val_[0]
  } else {
    $val = $value
  }
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


