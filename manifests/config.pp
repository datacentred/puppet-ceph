# == Class: ceph::config
#
# Configures ceph via ceph.conf
#
class ceph::config {

  assert_private()

  if $::ceph::conf_merge {
    $_conf = hiera_hash('ceph::conf')
  } else {
    $_conf = $::ceph::conf
  }

  file { '/etc/ceph/ceph.conf':
    ensure  => file,
    owner   => 'ceph',
    group   => 'ceph',
    mode    => '0644',
    content => template('ceph/ceph.conf.erb'),
  }

}
