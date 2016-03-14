class scaleio::gui_server (
  $ensure = 'present',
)
{
  if $ensure == 'absent'
  {
	  package { 'emc_scaleio_gui':
	    provider  => dpkg,
	    ensure    => absent}
  }
  else {
	  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }  
	  package { ['numactl', 'libaio1']:
	      ensure  => installed,
	  } ->
	  # Below are a java 1.8 installation steps which shouldn't be required for newer Ubuntu versions
	  exec { 'add java8 repo':
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
	  package { 'emc_scaleio_gui':
	    provider  => dpkg,
	    source    => '/home/alevine/shared/EMC-ScaleIO-gui-2.0-5014.0.deb',
	    ensure    => $ensure,
	  }
  }
  
  # TODO:
  # "absent" cleanup
}
