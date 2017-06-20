type Ceph::Keys = Hash[String[1], Struct[{
  user               => String[1],
  key                => String[1],
  Optional[caps_mon] => String[1],
  Optional[caps_osd] => String[1],
  Optional[caps_mds] => String[1],
}]]
