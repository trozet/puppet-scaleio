# Configure ScaleIO GUI installation

class scaleio::gui_server (
  $ensure = 'present',  # present|absent - Install or remove GUI
)
{
  require scaleio
  require scaleio::packages

  $gui_package = $::osfamily ? {
      'RedHat' => 'EMC-ScaleIO-gui',
      'Debian' => 'emc-scaleio-gui',
  }

  if $ensure == 'absent'
  {
    package { $gui_package:
      ensure    => absent,
    }
  }
  else {
    package { $gui_package:
      ensure  => installed,
    }
  }

  # TODO:
  # "absent" cleanup
}
