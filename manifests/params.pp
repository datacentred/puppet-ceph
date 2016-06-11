# == Class: ceph::params
#
# Static platform differences
#
class ceph::params {

  $repo_version = 'jewel'

  case $::operatingsystem {
    'Ubuntu': {
      if ( $::lsbmajdistrelease + 0 ) >= 16.04 {
        $service_provider = 'systemd'
      } else {
        $service_provider = 'upstart'
      }
      $manage_repo = true
      $repo_release = $::lsbdistcodename
      $radosgw_package = 'radosgw'
      $prerequisites = []
    }
    'RedHat', 'Centos': {
      if ( $::lsbmajdistrelease + 0 ) >= 7 {
        $service_provider = 'systemd'
      } else {
        $service_provider = 'sysvinit'
      }
      $manage_repo = false
      $repo_release = undef
      $radosgw_package = 'ceph-radosgw'
      # Broken on centos with 0.94.6
      $prerequisites = [
        'redhat-lsb-core',
      ]
    }
    default: {
      err('Unsupported operating system')
    }
  }

}
