# == Define: ceph::config_entry
#
# Define a ceph.conf configuration setting
#
# === Parameters
#
# [*name*]
#   Section and setting e.g. 'global/fsid'
#
# [*value*]
#   Desired setting value
#
define ceph::config_entry (
  $value,
) {

  private()

  $section_setting = split($name, '/')
  $section = $section_setting[0]
  $setting = $section_setting[1]

  ini_setting { "ceph.conf_${name}":
    section => $section,
    setting => $setting,
    value   => $value,
    path    => '/etc/ceph/ceph.conf',
  }

}
