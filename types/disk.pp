type Ceph::Disk = Pattern[
  /\A\/dev\/[a-z]+\Z/,
  /\A\d+:\d+:\d+:\d+\Z/,
  /\ASlot \d{2}\Z/,
  /\ADISK\d{2}\Z/,
]
