# == Class: ceph::auth
#
# Creates the requested keyrings on the host
#
class ceph::auth {

  assert_private()

  if $::ceph::keys_merge {
    $_keys = hiera_hash('ceph::keys')
  } else {
    $_keys = $::ceph::keys
  }

  create_resources('ceph::keyring', $_keys)

}
