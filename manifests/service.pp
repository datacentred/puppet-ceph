# == Class: ceph::service
#
# Configure and global services
#
class ceph::service {

  if $::ceph::service_provider == 'systemd' {
    exec { 'ceph.target enable':
      command => '/bin/systemctl enable ceph.target',
      unless  => '/bin/systemctl is-enabled ceph.target',
    } ~>

    # Oddly I've seen OSD udev rules not applying on Xenial which are
    # fixed with a reload
    exec { 'ceph::service systemctl reload':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }

}
