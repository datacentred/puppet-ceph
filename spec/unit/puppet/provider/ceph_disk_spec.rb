require 'spec_helper'

describe Puppet::Type.type(:osd).provider(:ceph_disk) do
  context '::scsi_address_to_dev' do
    it 'translates a scsi address to a block device' do
      sysfs_root = '/sys/class/scsi_disk'
      sysfs_root_contents = ['.', '..', '0:0:0:0', '1:0:0:0']
      sysfs_device = '/sys/class/scsi_disk/1:0:0:0/device/block'
      sysfs_device_contents = ['.', '..', 'sdb']

      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)
      File.stubs(:exist?).with(sysfs_device).returns(true)
      Dir.stubs(:entries).with(sysfs_device).returns(sysfs_device_contents)

      expect(described_class.scsi_address_to_dev('1:0:0:0')).to eq('/dev/sdb')
    end

    it 'returns nil if the scsi address is non-existant' do
      sysfs_root = '/sys/class/scsi_disk'
      sysfs_root_contents = ['.', '..', '0:0:0:0']

      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)

      expect(described_class.scsi_address_to_dev('1:0:0:0')).to be_nil
    end

    it 'returns nil if the block device directory is non-existant' do
      sysfs_root = '/sys/class/scsi_disk'
      sysfs_root_contents = ['.', '..', '0:0:0:0', '1:0:0:0']
      sysfs_device = '/sys/class/scsi_disk/1:0:0:0/device/block'

      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)
      File.stubs(:exist?).with(sysfs_device).returns(false)

      expect(described_class.scsi_address_to_dev('1:0:0:0')).to be_nil
    end

    it 'returns nil if the block device is non-existant' do
      sysfs_root = '/sys/class/scsi_disk'
      sysfs_root_contents = ['.', '..', '0:0:0:0', '1:0:0:0']
      sysfs_device = '/sys/class/scsi_disk/1:0:0:0/device/block'
      sysfs_device_contents = ['.', '..']

      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)
      Dir.stubs(:entries).with(sysfs_device).returns(sysfs_device_contents)

      expect(described_class.scsi_address_to_dev('1:0:0:0')).to be_nil
    end
  end

  context '::enclosure_slot_to_dev' do
    it 'translates an enclosure slot to a block device' do
      sysfs_root = '/sys/class/enclosure'
      sysfs_root_contents = ['.', '..', '2:0:0:2']
      sysfs_device = '/sys/class/enclosure/2:0:0:2/Slot 02/device/block'
      sysfs_device_contents = ['.', '..', 'sdd']

      File.stubs(:exist?).with(sysfs_root).returns(true)
      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)
      File.stubs(:exist?).with(sysfs_device).returns(true)
      Dir.stubs(:entries).with(sysfs_device).returns(sysfs_device_contents)

      expect(described_class.enclosure_slot_to_dev('Slot 02')).to eq('/dev/sdd')
    end

    it 'returns nil if no enclosure is detected' do
      sysfs_root = '/sys/class/enclosure'

      File.stubs(:exist?).with(sysfs_root).returns(false)

      expect(described_class.enclosure_slot_to_dev('Slot 02')).to be_nil
    end

    it 'returns nil if more than one enclosure is detected' do
      sysfs_root = '/sys/class/enclosure'
      sysfs_root_contents = ['.', '..', '2:0:0:2', '3:0:0:2']

      File.stubs(:exist?).with(sysfs_root).returns(true)
      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)

      expect(described_class.enclosure_slot_to_dev('Slot 02')).to be_nil
    end

    it 'returns nil if the block device directory is non-existant' do
      sysfs_root = '/sys/class/enclosure'
      sysfs_root_contents = ['.', '..', '2:0:0:2']
      sysfs_device = '/sys/class/enclosure/2:0:0:2/Slot 02/device/block'

      File.stubs(:exist?).with(sysfs_root).returns(true)
      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)
      File.stubs(:exist?).with(sysfs_device).returns(false)

      expect(described_class.enclosure_slot_to_dev('Slot 02')).to be_nil
    end

    it 'returns nil if the block device is non-existant' do
      sysfs_root = '/sys/class/enclosure'
      sysfs_root_contents = ['.', '..', '2:0:0:2']
      sysfs_device = '/sys/class/enclosure/2:0:0:2/Slot 02/device/block'
      sysfs_device_contents = ['.', '..']

      File.stubs(:exist?).with(sysfs_root).returns(true)
      Dir.stubs(:entries).with(sysfs_root).returns(sysfs_root_contents)
      File.stubs(:exist?).with(sysfs_device).returns(true)
      Dir.stubs(:entries).with(sysfs_device).returns(sysfs_device_contents)

      expect(described_class.enclosure_slot_to_dev('Slot 02')).to be_nil
    end
  end

  context '::identifier_to_dev' do
    it 'returns a block device if called with an absolute path' do
      expect(described_class.identifier_to_dev('/dev/nvme0n1')).to eq('/dev/nvme0n1')
    end

    it 'returns a block device if called with a slot ID' do
      described_class.stubs(:enclosure_slot_to_dev).with('Slot 01').returns('/dev/sdb')

      expect(described_class.identifier_to_dev('Slot 01')).to eq('/dev/sdb')
    end

    it 'returns a block device if called with a disk ID' do
      described_class.stubs(:enclosure_slot_to_dev).with('DISK00').returns('/dev/sdb')

      expect(described_class.identifier_to_dev('DISK00')).to eq('/dev/sdb')
    end

    it 'returns a block device if called with a scsi address' do
      described_class.stubs(:scsi_address_to_dev).with('2:0:0:0').returns('/dev/sdb')

      expect(described_class.identifier_to_dev('2:0:0:0')).to eq('/dev/sdb')
    end

    it 'returns nil if called with an illegal addressing method' do
      expect(described_class.identifier_to_dev('Mickey Mouse')).to be_nil
    end
  end

  context '::device_prepared?' do
    it 'returns true if the device is a regular osd' do
      sgdisk = <<-EOS
        Partition GUID code: 4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D (Unknown)
        Partition unique GUID: 784C47C1-3FA2-4E46-B53D-E1896FA4A550
        First sector: 2048 (at 1024.0 KiB)
        Last sector: 7814037134 (at 3.6 TiB)
        Partition size: 7814035087 sectors (3.6 TiB)
        Attribute flags: 0000000000000000
        Partition name: 'ceph data'
      EOS

      Puppet::Util::Execution.stubs(:execute).with('sgdisk -i 1 /dev/sdb').returns(sgdisk)

      expect(described_class.device_prepared?('/dev/sdb')).to eq(true)
    end

    it 'returns false if the device is not an osd' do
      sgdisk = <<-EOS
        Partition GUID code: 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem)
        Partition unique GUID: D8A68275-1217-4D9C-8752-1FB1D0AB0D25
        First sector: 2048 (at 1024.0 KiB)
        Last sector: 499711 (at 244.0 MiB)
        Partition size: 497664 sectors (243.0 MiB)
        Attribute flags: 0000000000000000
        Partition name: 'Linux filesystem'
      EOS

      Puppet::Util::Execution.stubs(:execute).with('sgdisk -i 1 /dev/sdb').returns(sgdisk)

      expect(described_class.device_prepared?('/dev/sdb')).to eq(false)
    end
  end

  context '::format_params' do
    it 'formats key value pairs correctly' do
      params = { 'fs-type' => 'xfs', 'cluster' => 'ceph' }

      expect(described_class.format_params(params)).to eq('--fs-type xfs --cluster ceph')
    end

    it 'formats null values correctly' do
      params = { 'bluestore' => :undef }

      expect(described_class.format_params(params)).to eq('--bluestore')
    end
  end

  context '::osd_prepare' do
    it 'prepares an osd device' do
      Puppet::Util::Execution.expects(:execute).with('ceph-disk prepare --fs-type xfs /dev/sdb /dev/sdc')

      described_class.osd_prepare('/dev/sdb', '/dev/sdc', 'fs-type' => 'xfs')
    end

    it 'does not emit parameters if none are given' do
      Puppet::Util::Execution.expects(:execute).with('ceph-disk prepare /dev/sdb /dev/sdc')

      described_class.osd_prepare('/dev/sdb', '/dev/sdc', {})
    end

    it 'does not emit journal if none given' do
      Puppet::Util::Execution.expects(:execute).with('ceph-disk prepare /dev/sdb')

      described_class.osd_prepare('/dev/sdb', nil, {})
    end
  end

  context '#exists?' do
    it 'returns true with valid required parameters and sets instance variables correctly' do
      resource = described_class.resource_type.new(:name => '0:0:0:0')

      described_class.stubs(:identifier_to_dev).with('0:0:0:0').returns('/dev/sdb')
      described_class.stubs(:device_prepared?).with('/dev/sdb').returns(true)

      expect(resource.provider.exists?).to eq(true)
      expect(resource.provider.instance_variable_get('@osd_dev')).to eq('/dev/sdb')
      expect(resource.provider.instance_variable_get('@journal_dev')).to be_nil
      expect(resource.provider.instance_variable_get('@params')).to eq({})
    end

    it 'returns true with valid optional parameters and sets instance variables correctly' do
      resource = described_class.resource_type.new(:name => '0:0:0:0', :journal => '1:0:0:0', :params => { 'fs-type' => 'xfs' })

      described_class.stubs(:identifier_to_dev).with('0:0:0:0').returns('/dev/sdb')
      described_class.stubs(:identifier_to_dev).with('1:0:0:0').returns('/dev/sdc')
      described_class.stubs(:device_prepared?).with('/dev/sdb').returns(true)

      expect(resource.provider.exists?).to eq(true)
      expect(resource.provider.instance_variable_get('@osd_dev')).to eq('/dev/sdb')
      expect(resource.provider.instance_variable_get('@journal_dev')).to eq('/dev/sdc')
      expect(resource.provider.instance_variable_get('@params')).to eq('fs-type' => 'xfs')
    end

    it 'returns true with invalid required parameters and warns' do
      resource = described_class.resource_type.new(:name => '0:0:0:0')

      described_class.stubs(:identifier_to_dev).with('0:0:0:0').returns(nil)

      resource.provider.expects(:warning)
      expect(resource.provider.exists?).to eq(true)
    end
  end

  context '#destroy' do
    it 'raises an error' do
      resource = described_class.resource_type.new(:name => '0:0:0:0', :journal => '1:0:0:0')

      expect do
        resource.provider.destroy
      end.to raise_error(Puppet::Error, /unsupported operation/)
    end
  end

  context '#create' do
    it 'calls osd_prepare with the correct arguments' do
      resource = described_class.resource_type.new(:name => '0:0:0:0', :journal => '1:0:0:0')

      described_class.stubs(:identifier_to_dev).with('0:0:0:0').returns('/dev/sdb')
      described_class.stubs(:identifier_to_dev).with('1:0:0:0').returns('/dev/sdc')
      described_class.stubs(:device_prepared?).with('/dev/sdb').returns(true)
      described_class.expects(:osd_prepare).with('/dev/sdb', '/dev/sdc', {})

      resource.provider.exists?
      resource.provider.create
    end
  end
end
