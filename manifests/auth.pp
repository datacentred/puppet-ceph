# == Class: ceph::auth
#
# Creates the requested keyrings on the host
#
# === Parameters
#
# [*keys*]
#   Hash of ceph::keyring resources to be created
#
class ceph::auth (
  $keys = {},
) {

  private()

  create_resources('ceph::keyring', $keys)

}
