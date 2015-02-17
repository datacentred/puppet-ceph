# == Class: ceph::auth
#
# Creates the requested keyrings on the host
#
class ceph::auth {

  assert_private()

  create_resources('ceph::keyring', $::ceph::keys)

}
