# lib/puppet/provider/osd/ceph_disk.rb
#
Puppet::Type.type(:osd).provide(:ceph_disk) do
private

  OSD_UUIDS = [
    '4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D', # regular
    '4FBD7E29-9D25-41B8-AFD0-35865CEFF05D', # luks
    '4FBD7E29-9D25-41B8-AFD0-5EC00CEFF05D', # plain
  ].freeze

  # Translate a scsi address into a device node
  # Params:
  # +address+:: SCSI address of the device in H:B:T:L format
  def self.scsi_address_to_dev(address)
    # Get a list of all detected scsi disks and see 'address' exists
    scsi_disks = Dir.entries('/sys/class/scsi_disk')
    return nil unless scsi_disks.include? address
    # Get the device node allocated by the kernel
    path = "/sys/class/scsi_disk/#{address}/device/block"
    return nil unless File.exist?(path)
    bd = Dir.entries(path).reject { |x| x.start_with? '.' }
    return nil unless bd.length == 1
    "/dev/#{bd.first}"
  end

  # Translate a slot number into a device node
  # Params:
  # +slot+:: Slot number of the SAS expander e.g. "Slot 02"
  def self.enclosure_slot_to_dev(slot)
    # Get the expander
    # TODO: Supports one enclosure services device, need a way of reliably
    #       addressing expanders
    path = '/sys/class/enclosure'
    return nil unless File.exist?(path)
    enclosures = Dir.entries(path).reject { |x| x.start_with? '.' }
    return nil unless enclosures.length == 1
    # Get the device from the enclosure slot
    path = "/sys/class/enclosure/#{enclosures.first}/#{slot}/device/block"
    return nil unless File.exist?(path)
    bd = Dir.entries(path).reject { |x| x.start_with? '.' }
    return nil unless bd.length == 1
    "/dev/#{bd.first}"
  end

  # Redirect the request to the correct SCSI backend
  # Params:
  # +indetifier+:: SCSI address or enclosure slot number
  def self.identifier_to_dev(identifier)
    if identifier.start_with?('/dev/')
      identifier
    elsif identifier.start_with?('Slot', 'DISK')
      enclosure_slot_to_dev(identifier)
    elsif identifier =~ /^\d+:\d+:\d+:\d+$/
      scsi_address_to_dev(identifier)
    end
  end

  # Check whether an OSD has been provisioned
  # Params:
  # +dev+:: Device short name e.g. sdd
  def self.device_prepared?(dev)
    sgdisk = Puppet::Util::Execution.execute("sgdisk -i 1 #{dev}")
    OSD_UUIDS.any? { |uuid| sgdisk.include?(uuid) }
  end

  # Format parameters
  # Params:
  # +params+:: Parameter hash
  def self.format_params(params)
    # Parameter list is stripped of leading hyphens
    # An undefined value is an option without an argument
    params.map do |k, v|
      v == :undef && "--#{k}" || "--#{k} #{v}"
    end.join(' ')
  end

  # Prepare an OSD
  # Params:
  # +data+:: Data device
  # +journal+:: Journal device
  # +params+:: Parameter hash
  def self.osd_prepare(data, journal, params)
    params = format_params(params)
    command = 'ceph-disk prepare'
    command << " #{params}" unless params.empty?
    command << " #{data}"
    command << " #{journal}" if journal
    Puppet::Util::Execution.execute(command)
  end

  # Evaluate arguments
  def eval_arguments
    @osd_dev = self.class.identifier_to_dev(resource[:name])
    return false unless @osd_dev
    if resource[:journal] != :undef
      @journal_dev = self.class.identifier_to_dev(resource[:journal])
      return false unless @journal_dev
    end
    @params = resource[:params] == :undef && {} || resource[:params]
    true
  end

public

  # Create the resource
  def create
    self.class.osd_prepare(@osd_dev, @journal_dev, @params)
  end

  # Destroy the resource
  def destroy
    raise Puppet::Error 'unsupported operation'
  end

  # Check if the resource exists
  def exists?
    unless eval_arguments
      warning 'unable to detect osd or journal device'
      # Let execution continue, the disk may be removed for a legitimate reason
      return true
    end
    # Check if the OSD device has been prepared
    self.class.device_prepared? @osd_dev
  end
end
