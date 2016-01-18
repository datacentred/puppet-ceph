# == Class: ceph::params
#
# Static platform differences
#
class ceph::params {

  case $::operatingsystem {
    'Ubuntu': {
      $service_provider = 'upstart'
      $radosgw_package = 'radosgw'
    }
    default: {
      $service_provider = 'sysvinit'
      $radosgw_package = 'ceph-radosgw'
    }
  }

}
