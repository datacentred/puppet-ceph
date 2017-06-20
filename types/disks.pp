type Ceph::Disks = Hash[Ceph::Disk, Struct[{
  Optional[journal] => Ceph::Disk,
  Optional[params]  => Hash[String[1], String[1]],
}]]
