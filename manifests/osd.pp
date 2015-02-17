# == Class: ceph::osd
#
# Installs a set of OSDs
#
# === Parameters
#
# [*disks*]
#   Hash of osd resources to create
#
class ceph::osd (
  $disks = {},
) {

  private()

  include ::ceph

  if $ceph::osd {

    create_resources('osd', $disks)

  }

}
