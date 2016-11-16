require 'spec_helper'

describe Puppet::Type.type(:osd) do
  context 'parameters' do
    it 'has :journal' do
      expect(described_class.attrtype(:journal)).to eq(:param)
    end

    it 'has :params' do
      expect(described_class.attrtype(:params)).to eq(:param)
    end
  end

  context ':name' do
    it 'accepts absolute paths' do
      expect do
        described_class.new(:name => '/dev/nvme0n1')
      end.to_not raise_error
    end

    it 'accepts scsi addresses' do
      expect do
        described_class.new(:name => '1:0:0:0')
      end.to_not raise_error
    end

    it 'accepts slot IDs' do
      expect do
        described_class.new(:name => 'Slot 01')
      end.to_not raise_error
    end

    it 'accepts disk IDs' do
      expect do
        described_class.new(:name => 'DISK00')
      end.to_not raise_error
    end

    it 'rejects other values' do
      expect do
        described_class.new(:name => 'Mickey Mouse')
      end.to raise_error(Puppet::ResourceError, /invalid value/)
    end

    it 'rejects other types' do
      expect do
        described_class.new(:name => 0)
      end.to raise_error(Puppet::ResourceError, /invalid type/)
    end
  end

  context ':journal' do
    it 'defaults to :undef' do
      expect(described_class.new(:name => '0:0:0:0')[:journal]).to eq(:undef)
    end

    it 'accepts absolute paths' do
      expect do
        described_class.new(:name => '0:0:0:0', :journal => '/dev/nvme0n1')
      end.to_not raise_error
    end

    it 'accepts scsi addresses' do
      expect do
        described_class.new(:name => '0:0:0:0', :journal => '1:0:0:0')
      end.to_not raise_error
    end

    it 'accepts slot IDs' do
      expect do
        described_class.new(:name => '0:0:0:0', :journal => 'Slot 01')
      end.to_not raise_error
    end

    it 'accepts disk IDs' do
      expect do
        described_class.new(:name => '0:0:0:0', :journal => 'DISK00')
      end.to_not raise_error
    end

    it 'rejects invalid values' do
      expect do
        described_class.new(:name => '0:0:0:0', :journal => 'Mickey Mouse')
      end.to raise_error(Puppet::ResourceError, /invalid value/)
    end

    it 'rejects invalid types' do
      expect do
        described_class.new(:name => '0:0:0:0', :journal => 0)
      end.to raise_error(Puppet::ResourceError, /invalid type/)
    end
  end

  context ':params' do
    it 'defaults to :undef' do
      expect(described_class.new(:name => '0:0:0:0')[:params]).to eq(:undef)
    end

    it 'accepts hashes of strings' do
      expect do
        described_class.new(
          :name => '0:0:0:0',
          :params => {
            'fs-type' => 'xfs'
          }
        )
      end.to_not raise_error
    end

    it 'accepts hashes of :undef' do
      expect do
        described_class.new(
          :name => '0:0:0:0',
          :params => {
            'dmcrypt' => :undef
          }
        )
      end.to_not raise_error
    end

    it 'rejects invalid types' do
      expect do
        described_class.new(
          :name => '0:0:0:0',
          :params => 0
        )
      end.to raise_error(Puppet::ResourceError, /invalid type/)
    end

    it 'rejects invalid keys' do
      expect do
        described_class.new(
          :name => '0:0:0:0',
          :params => {
            0 => 'a'
          }
        )
      end.to raise_error(Puppet::ResourceError, /invalid key type/)
    end

    it 'rejects invalid key values' do
      expect do
        described_class.new(
          :name => '0:0:0:0',
          :params => {
            'fs-type' => 0
          }
        )
      end.to raise_error(Puppet::ResourceError, /invalid value type/)
    end
  end
end
