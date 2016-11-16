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
    else
      scsi_address_to_dev(identifier)
    end
  end

  # Check whether an OSD has been provisioned
  # Params:
  # +dev+:: Device short name e.g. sdd
  def self.device_prepared?(dev)
    sgdisk = `sgdisk -i 1 #{dev}`
    OSD_UUIDS.any? { |uuid| sgdisk.include?(uuid) }
  end

  # Prepare an OSD
  def osd_prepare
    # Parameter list is stripped of leading hyphens
    # An undefined value is an option without an argument
    params = resource[:params].map do |k, v|
      v == :undef ? "--#{k}" : "--#{k} #{v}"
    end.join(' ')
    command = 'ceph-disk prepare'
    command << " #{params}" unless params.empty?
    command << " #{@osd_dev}"
    command << " #{@journal_dev}" if @journal_dev
    Puppet::Util::Execution.execute(command)
  end

  # Activate an OSD
  def osd_activate
    # Upstart automatically does this for us via udev events
    return unless :operatingsystem == 'Ubuntu'
    command = "ceph-disk activate #{@osd_dev}1"
    Puppet::Util::Execution.execute(command)
  end

  # Evaluate arguments
  def eval_arguments
    @osd_dev = identifier_to_dev(resource[:name])
    return false unless @osd_dev
    if resource[:journal] != :undef
      @journal_dev = identifier_to_dev(resource[:journal])
      return false unless @journal_dev
    end
    true
  end

public

  # Create the resource
  def create
    osd_prepare
    osd_activate
  end

  # Destroy the resource
  def destroy
    raise Puppet::Error 'unsupported operation'
  end

  # Check if the resource exists
  def exists?
    unless eval_arguments
      warning "unable to detect osd or journal device for #{resource[:name]}"
      # Let execution continue, the disk may be removed for a legitimate reason
      return true
    end
    # Check if the OSD device has been prepared
    device_prepared? @osd_dev
  end
end
