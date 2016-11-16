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
    desc 'OSD identifier'
    validate do |value|
      resource.validate_address(value)
    end
  end

  newparam(:journal) do
    desc 'Journal identifier'
    defaultto :undef
    validate do |value|
      resource.validate_address(value) if value != :undef
    end
  end

  newparam(:params) do
    desc 'Parameter list to be passed to ceph-disk'
    defaultto :undef
    validate do |value|
      resource.validate_params(value) if value != :undef
    end
  end

  def validate_address(address)
    raise ArgumentError, 'osd::validate_address invalid type' unless address.is_a?(String)
    # Device nodes (not officially supported)
    return if address.start_with?('/dev/')
    # SCSI address e.g. 1:0:0:0
    return if address =~ /^\d+:\d+:\d+:\d+$/
    # Expander slot e.g. Slot 01, DISK00
    return if address =~ /^(Slot \d{2}|DISK\d{2})$/
    raise ArgumentError, 'osd::validate_address invalid value'
  end

  def validate_params(params)
    raise ArgumentError, 'osd::validate_params invalid type' unless params.is_a?(Hash)
    raise ArgumentError, 'osd::validate_params invalid key type' unless params.keys.all? { |k| k.is_a?(String) }
    raise ArgumentError, 'osd::validate_params invalid value type' unless params.values.all? { |v| v.is_a?(String) || v == :undef }
  end

  autorequire(:package) do
    'ceph'
  end

  autorequire(:file) do
    '/var/lib/ceph/bootstrap-osd/ceph.keyring'
  end
end
