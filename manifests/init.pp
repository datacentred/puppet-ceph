# == Class: ceph
#
# Install ceph
#
# === Parameters
#
# [*mon*]
#   Install a monitor
#
# [*osd*]
#   Install osds
#
# [*rgw*]
#   Install an object gateway
#
# [*manage_repo*]
#   Whether this module should install custom repos
#
# [*repo_version*]
#   Ceph version to install the repo for
#
# [*conf*]
#   Hash of ceph config file
#
# [*mon_id*]
#   Human readable monitor name, defaults to hostname
#
# [*mon_key*]
#   mon. authentication key shared between monitors
#
# [*keys*]
#   Hash of ceph::keyring resources to be created
#
# [*disks*]
#   Hash of osd resources to create
#
# [*rgw_id*]
#   Gateway identifier
#
class ceph (
  # Install component
  $mon = false,
  $osd = false,
  $rgw = false,
  # Package management
  $manage_repo = false,
  $repo_version = 'hammer',
  # Global configuration
  $conf = {
    'global' => {
      'fsid' => '62ed9bd6-adf4-11e4-8fb5-3c970ebb2b86',
      'mon_initial_members' => $::hostname,
      'mon_host' => $::ipaddress,
      'public_network' => "${::network_eth0}/24",
      'cluster_network' => "${::network_eth0}/24",
      'auth_supported' => 'cephx',
      'filestore_xattr_use_omap' => true,
      'osd_crush_chooseleaf_type' => '0',
    },
    'osd' => {
      'osd_journal_size' => 100,
    },
  },
  # Monitor configuration
  $mon_id = $::hostname,
  $mon_key = 'AQA7yNlUMy3sFhAA62XHf57L0QhSI44qqqOVXA==',
  # Key management
  $keys = {
    '/etc/ceph/ceph.client.admin.keyring' => {
      'user'     => 'client.admin',
      'key'      => 'AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA==',
      'caps_mon' => 'allow *',
      'caps_osd' => 'allow *',
      'caps_mds' => 'allow',
    },
    '/var/lib/ceph/bootstrap-osd/ceph.keyring' => {
      'user'     => 'client.bootstrap-osd',
      'key'      => 'AQDLGtpUdYopJxAAnUZHBu0zuI0IEVKTrzmaGg==',
      'caps_mon' => 'allow profile bootstrap-osd',
    },
    '/var/lib/ceph/bootstrap-mds/ceph.keyring' => {
      'user'     => 'client.bootstrap-mds',
      'key'      => 'AQDLGtpUlWDNMRAAVyjXjppZXkEmULAl93MbHQ==',
      'caps_mon' => 'allow profile bootstrap-mds',
    },
  },
  # OSD management
  $disks = {
    '2:0:0:0/5:0:0:0' => {
      'fstype' => 'xfs',
    },
    '3:0:0:0/5:0:0:0' => {
      'fstype' => 'xfs',
    },
    '4:0:0:0/5:0:0:0' => {
      'fstype' => 'xfs',
    },
  },
  # RGW configuration
  $rgw_id = $::hostname,
) {

  contain ::ceph::repo
  contain ::ceph::install
  contain ::ceph::config
  contain ::ceph::mon
  contain ::ceph::auth
  contain ::ceph::osd
  contain ::ceph::rgw

  Class['::ceph::repo'] ->
  Class['::ceph::install'] ->
  Class['::ceph::config'] ->
  Class['::ceph::mon'] ->
  Class['::ceph::auth'] ->
  Class['::ceph::osd'] ->
  Class['::ceph::rgw']

}
