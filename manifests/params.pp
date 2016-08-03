# == Class: ceph::params
#
# Static platform differences
#
class ceph::params {

  case $::operatingsystem {
    'Ubuntu': {
      $service_provider = 'debian'
      $radosgw_package = 'radosgw'
      $prerequisites = []
    }
    'RedHat', 'Centos': {
      $service_provider = 'redhat'
      $radosgw_package = 'ceph-radosgw'
      $prerequisites = [
        'redhat-lsb-core',            # Broken on centos with 0.94.6
        'python-setuptools.noarch',   # Needed by /usr/bin/ceph-detect-init
      ]
    }
    default: {
      err('Unsupported operating system')
    }
  }

}
