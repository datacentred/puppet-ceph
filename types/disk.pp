type Ceph::Disk = Pattern[
  /\A\/dev\/[\w\d]+\Z/,
  /\A\d+:\d+:\d+:\d+\Z/,
  /\ASlot \d{2}\Z/,
  /\ADISK\d{2}\Z/,
]
