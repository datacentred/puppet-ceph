# == Class: ceph::params
#
# Static platform differences
#
class ceph::params {

  case $::operatingsystem {
    'Ubuntu': {
      $service_provider = 'upstart'
      $radosgw_package = 'radosgw'
      $prerequisites = []
    }
    'RedHat', 'Centos': {
      $service_provider = 'sysvinit'
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
