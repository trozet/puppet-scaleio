class scaleio::cluster (
  $mdm_ip             = undef,
  $cluster3_ips       = undef,
  $cluster5_ips       = undef,
  $ensure             = undef,
  $password           = 'admin',
  $new_password       = undef,)
{

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
  
  define create_cluster($mdm_ip) {
    if $mdm_ip {
		  exec { 'create cluster':
		    command => "scli --approve_certificate --accept_license --create_mdm_cluster  --use_nonsecure_communication --master_mdm_ip ${mdm_ip}",
		    unless => 'scli --query_cluster --approve_certificate',
      }
    }
  }
  
  define change_password($password, $new_password) {
    if $new_password {
	    exec { 'change password':
	      command => "scli --set_password --approve_certificate --old_password ${password} --new_password ${new_password}",
        require => Class['scaleio::login'],
      }
    }
  }
  
  create_cluster { 'cluster': mdm_ip => $mdm_ip } ~>
  scaleio::login { 'login': password => $password }
  change_password { 'password': password => $password, new_password => $new_password,}
}
