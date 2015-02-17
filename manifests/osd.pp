# == Class: ceph::osd
#
# Installs a set of OSDs
#
class ceph::osd {

  assert_private()

  if $::ceph::osd {

    create_resources('osd', $::ceph::disks)

  }

}
