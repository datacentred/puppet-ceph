# == Class: ceph::config
#
# Configures ceph via ceph.conf
#
# === Parameters
#
# [*values*]
#   Hash of ceph::config_entry resources to be created
#
class ceph::config (
  $values = {}
) {

  private()

  create_resources('ceph::config_entry', $values)

}
