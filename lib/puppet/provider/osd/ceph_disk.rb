# lib/puppet/provider/osd/ceph_disk.rb
#
Puppet::Type.type(:osd).provide(:ceph_disk) do

private

  OSD_UUID = '4fbd7e29-9d25-41b8-afd0-062c0ceff05d'

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
    if identifier.start_with?('Slot')
      enclosure_slot_to_dev(identifier)
    else
      scsi_address_to_dev(identifier)
    end
  end

  # Check whether an OSD has been provisioned 
  # Params:
  # +dev+:: Device short name e.g. sdd
  def device_prepared?(dev)
    if Dir.exists? '/dev/disk/by-parttypeuuid'
      begin
        partitions = Dir.entries('/dev/disk/by-parttypeuuid').select { |x| not x.start_with? '.' }
      rescue Errno::ENOENT
        return false
      end
    else
      partitions = Puppet::Util::Execution.execute('lsblk -o parttype,kname').split(/\n/)
    end
    partitions.each do |partition|
      if partition.start_with? OSD_UUID
	if Dir.exists? '/dev/disk/by-parttypeuuid'
          target = File.readlink "/dev/disk/by-parttypeuuid/#{partition}"
	else
	  target = partition
	end
        return true if /#{dev}\d+$/ =~ target
      end
    end
    false
  end

public

  # Create the resource
  def create
    command = "ceph-disk prepare --fs-type #{@fstype} /dev/#{@osd_dev} /dev/#{@journal_dev}"
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
    osd, journal = resource[:name].split '/'
    @fstype = resource[:fstype]
    begin
      @osd_dev = identifier_to_dev(osd)
      @journal_dev = identifier_to_dev(journal)
    rescue RuntimeError
      # Either the device isn't physically present or didn't have a device node
      # Valid state if a machine has a faulty drive slot for example
      warning "unable to detect device #{osd}"
      return true
    end
    device_prepared? @osd_dev
  end

end
