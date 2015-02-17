# == Class: ceph::config
#
# Configures ceph via ceph.conf
#
class ceph::config {

  assert_private()

  file { '/etc/ceph/ceph.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('ceph/ceph.conf.erb'),
  }

}
