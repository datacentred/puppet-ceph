# == Class: ceph::service
#
# Configure and global services
#
class ceph::service {

  if $::ceph::service_provider == 'systemd' {
    exec { 'systemctl enable ceph.target':
      unless => 'systemctl is-enabled ceph.target',
    }
  }

}
