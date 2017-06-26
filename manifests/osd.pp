# == Class: ceph::osd
#
# Installs a set of OSDs
#
class ceph::osd {

  assert_private()

  if $::ceph::osd {

    if has_key($::ceph::disks, 'defaults') {
      $_defaults = $::ceph::disks['defaults']
      $_disks = delete($::ceph::disks, 'defaults')
    } else {
      $_defaults = {}
      $_disks = $::ceph::disks
    }

    create_resources('osd', $_disks, $_defaults)

  }

}
