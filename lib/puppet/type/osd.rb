# lib/puppet/type/osd.rb
#
# Use case:
#
# osd { '3:0:0:0':
#   journal => '4:0:0:0',
#   params  => {
#     'fstype' => 'btrfs',
#   },
# }
#
# osd { 'Slot 01':
#   journal => 'Slot 01',
#   params => {
#     'bluetore' => undef,
#     'fstype'   => 'xfs',
#   },
# }
#
Puppet::Type.newtype(:osd) do
  @doc = 'Create an OSD based on physical hardware address'

  ensurable do
    defaultvalues
    defaultto 'present'
  end

  newparam(:name) do
    desc 'OSD SCSI addresses which can be specified as "H:B:T:L" for direct attached or "Slot 01" for expander devices'
    validate do |value|
      resource.validate_address(value)
    end
  end

  newparam(:journal) do
    desc 'Device to create journal from specified as "H:B:T:L" for direct attached or "Slot 01" for expander devices'
    defaultto :undef
    validate do |value|
      value && resource.validate_address(value)
    end
  end

  newparam(:params) do
    desc 'Parameter list to be passed to ceph-disk'
    defaultto {}
    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, 'osd::params parameter list should be a hash'
      end
      unless value.keys.all? { |k| k.is_a?(String) }
        raise ArgumentError, 'osd::params parameter keys should be strings'
      end
      unless value.values.all? { |v| v.is_a?(String) || v == :undef }
        raise ArgumentError, 'osd::params parameter values should be strings or undef'
      end
    end
  end

  def validate_address(address)
    unless address =~ /^(\d+:\d+:\d+:\d+|Slot \d{2}|DISK\d{2})$/
      raise ArgumentError, 'osd::validate_address device identifier invalid'
    end
  end

  autorequire(:package) do
    'ceph'
  end

  autorequire(:file) do
    '/var/lib/ceph/bootstrap-osd/ceph.keyring'
  end

end
