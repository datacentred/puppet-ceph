# lib/puppet/provider/osd/ceph_disk.rb
#
Puppet::Type.type(:osd).provide(:ceph_disk) do

private

  OSD_UUIDS = [
    '4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D', # regular
    '4FBD7E29-9D25-41B8-AFD0-35865CEFF05D', # luks
    '4FBD7E29-9D25-41B8-AFD0-5EC00CEFF05D', # plain
  ]

  # Translate a scsi address into a device node
  # Params:
  # +address+:: SCSI address of the device in H:B:T:L format
  def scsi_address_to_dev(address)
    # Get a list of all detected scsi disks and see 'address' exists
    scsi_disks = Dir.entries('/sys/class/scsi_disk')
    raise RuntimeError if not scsi_disks.include? address
    # Get the device node allocated by the kernel
    bd = Dir.entries("/sys/class/scsi_disk/#{address}/device/block").select { |x| not x.start_with? '.' }
    raise RuntimeError if bd.length != 1
    bd[0]
  end

  # Translate a slot number into a device node
  # Params:
  # +slot+:: Slot number of the SAS expander e.g. "Slot 02"
  def enclosure_slot_to_dev(slot)
    # Get the expander
    # TODO: Supports one enclosure services device, need a way of reliably addressing expanders
    enclosures = Dir.entries('/sys/class/enclosure').reject { |x| x =~ /^\./ }
    raise RuntimeError if enclosures.length > 1
    # Get the device from the enclosure slot
    blockdir = "/sys/class/enclosure/#{enclosures.first}/#{slot}/device/block"
    raise RuntimeError if not File.exists?(blockdir)
    Dir.entries(blockdir).reject { |x| x =~ /^\./ }.first
  end

  # Redirect the request to the correct SCSI backend
  # Params:
  # +indetifier+:: SCSI address or enclosure slot number
  def identifier_to_dev(identifier)
    if identifier.start_with?('Slot', 'DISK')
      enclosure_slot_to_dev(identifier)
    else
      scsi_address_to_dev(identifier)
    end
  end

  # Check whether an OSD has been provisioned 
  # Params:
  # +dev+:: Device short name e.g. sdd
  def device_prepared?(dev)
    sgdisk = %x{sgdisk -i 1 /dev/#{dev}}
    OSD_UUIDS.any? { |uuid| sgdisk.include?(uuid) }
  end

public

  # Create the resource
  def create
    command = "ceph-disk prepare"
    command << " " + resource[:params].map { |k, v| v == :undef ? "--#{k}" : "--#{k} #{v}" }.join(' ')
    command << "  /dev/#{@osd_dev}"
    if @journal_dev
      command << " /dev/#{@journal_dev}"
    end
    Puppet::Util::Execution.execute(command)
    # Upstart automatically does this for us via udev events
    if :operatingsystem != 'Ubuntu'
      command = "ceph-disk activate /dev/#{@osd_dev}1"
      Puppet::Util::Execution.execute(command)
    end
  end

  # Destroy the resource
  def destroy
    raise Puppet::Error 'unsupported operation'
  end

  # Check if the resource exists
  def exists?
    # Check if the main OSD device can be resolved
    begin
      @osd_dev = identifier_to_dev(resource[:name])
    rescue RuntimeError
      warning "unable to detect osd device #{resource[:name]}"
      return true
    end
    # Check if the optional journal device can be resolved
    if resource[:journal]
      begin
        @journal_dev = identifier_to_dev(resource[:journal])
      rescue RuntimeError
        warning "unable to detect journal device #{resource[:journal]}"
        return true
      end
    end
    # Check if the OSD device has been prepared
    device_prepared? @osd_dev
  end

end
