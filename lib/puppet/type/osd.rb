# lib/puppet/type/osd.rb
#
# Use case:
#
# osd { '3:0:0:0/4:0:0:0':
#   fstype => 'btrfs',
# }
#
# osd { 'Slot 01/Slot 01':
#   fstype => 'xfs',
# }
#
# osd { '5:0:0:0/5:0:0:0':
#   dmcrypt         => true,
#   dmcrypt_key_dir => '/etc/ceph/luks-keys',
# }
#
Puppet::Type.newtype(:osd) do
  @doc = 'Create an OSD based on physical hardware address'

  ensurable do
    defaultvalues
    defaultto 'present'
  end

  newparam(:name) do
    desc 'OSD and journal SCSI addresses which can be specified as "H:B:T:L" for direct attached or "Slot 01" for expander devices'
    validate do |value|
      unless value =~ /^(\d+:\d+:\d+:\d+|Slot \d{2})\/(\d+:\d+:\d+:\d+|Slot \d{2})$/
        raise ArgumentError, 'osd::name invalid'
      end
    end
  end

  newparam(:fstype) do
    desc 'OSD file system type'
    defaultto 'xfs'
    validate do |value|
      unless ['xfs', 'btrfs', 'ext4'].include? value
        raise ArgumentError, 'osd::fstype unsupporded'
      end
    end
  end

  newparam(:dmcrypt) do
    desc 'Enable encryption of the underlying disk'
    defaultto false
    validate do |value|
      unless !!value == value
        raise ArgumentError, 'osd::dmcrypt is not boolean'
      end
    end
  end

  newparam(:dmcrypt_key_dir) do
    desc 'Set directory to store encryption keys for encrypted OSD disks'
    defaultto '/etc/ceph/dmcrypt-keys'
    validate do |value|
      require 'pathname'
      unless (Pathname.new value).absolute?
        raise ArgumentError, 'osd::dmcrypt_key_dir must be an absolue path'
      end
    end
  end

  autorequire(:package) do
    'ceph'
  end

  autorequire(:file) do
    '/var/lib/ceph/bootstrap-osd/ceph.keyring'
  end

end
