# lib/puppet/type/osd.rb
#
# Use case:
#
# osd { '3:0:0:0/4:0:0:0':
#   fstype => 'btrfs',
# }
#
Puppet::Type.newtype(:osd) do
  @doc = 'Create an OSD based on physical hardware address'

  ensurable do
    defaultvalues
    defaultto 'present'
  end

  newparam(:name) do
    desc 'OSD and journal SCSI addresses in the form "H:B:T:L/H:B:T:L"'
    validate do |value|
      unless value =~ /^\d+:\d+:\d+:\d+\/\d+:\d+:\d+:\d+$/
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

  autorequire(:package) do
    'ceph'
  end

  autorequire(:file) do
    '/var/lib/ceph/bootstrap-osd/ceph.keyring'
  end

end
