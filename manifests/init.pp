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
# [*repo_release*]
#   OS release version.  Only LTS is supported
#
# [*conf_merge*]
#   Ignore the value bound to ceph::conf and perform a
#   hiera_hash call to merge config fragments tegether
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
# [*keys_merge*]
#   Ignore the value bound to ceph::keys and perform a
#   hiera_hash call to merge keys together
#
# [*keys*]
#   Hash of ceph::keyring resources to be created
#
# [*disks*]
#   Hash of osd resources to create
#
class ceph (
  # Install component
  $mon = false,
  $osd = false,
  $rgw = false,
  # Package management
  $manage_repo = true,
  $repo_version = 'hammer',
  $repo_release = 'trusty',
  # Global configuration
  $conf_merge = false,
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
    'client.rgw' => {
      'keyring' => '/etc/ceph/ceph.client.rgw.keyring',
    },
  },
  # Monitor configuration
  $mon_id = $::hostname,
  $mon_key = 'AQA7yNlUMy3sFhAA62XHf57L0QhSI44qqqOVXA==',
  # Key management
  $keys_merge = false,
  $keys = {
    '/etc/ceph/ceph.client.admin.keyring' => {
      'user'     => 'client.admin',
      'key'      => 'AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA==',
      'caps_mon' => 'allow *',
      'caps_osd' => 'allow *',
      'caps_mds' => 'allow',
    },
    '/etc/ceph/ceph.client.rgw.keyring' => {
      'user'     => 'client.rgw',
      'key'      => 'AQD+zXZVDljeKRAAKA30V/QvzbI9oUtcxAchog==',
      'caps_mon' => 'allow rwx',
      'caps_osd' => 'allow rwx',
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
  # RGW management
  $rgw_id = 'rgw',
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
