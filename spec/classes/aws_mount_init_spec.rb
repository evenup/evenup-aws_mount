require 'spec_helper'

describe 'aws_mount', :type => :class do
  let(:facts) { { :ec2_instance_type => 'm1.small', :ec2_block_device_mapping_ephemeral0 => '/dev/sdb', :ec2_block_device_mapping_ephemeral1 => nil, :ec2_block_device_mapping_ephemeral2 => nil, :ec2_block_device_mapping_ephemeral3 => nil } }

  it { should create_class('aws_mount') }

  context "all instance types" do
    it { should contain_package('mdadm') }
    it { should contain_package('xfsprogs') }

    it { should contain_file('/data') }
    it { should contain_file('/data/tmp').with_mode('1777') }
  end

  context "no ephemeral" do
    let(:facts) { { :ec2_instance_type => 'm1.small', :ec2_block_device_mapping_ephemeral0 => nil, :ec2_block_device_mapping_ephemeral1 => nil, :ec2_block_device_mapping_ephemeral2 => nil, :ec2_block_device_mapping_ephemeral3 => nil } }

    it { should_not contain_mount('/data') }
  end

  context "set mount_point" do
    let(:params) { { :mount_point => '/somewhere' } }
#    it { should contain_file('/somewhere') }
#    it { should contain_file('/somewhere/tmp') }
  end

  context "no disks instance" do
    let(:facts) { { :ec2_instance_type => 'm3.2xlarge', :ec2_block_device_mapping_ephemeral0 => nil, :ec2_block_device_mapping_ephemeral1 => nil, :ec2_block_device_mapping_ephemeral2 => nil, :ec2_block_device_mapping_ephemeral3 => nil } }
    it { should_not contain_mount('/data') }
  end

  context "single disk" do
    context "ephemeral disk" do
      let(:facts) { { :ec2_instance_type => 'm1.small', :ec2_block_device_mapping_ephemeral0 => '/dev/sdb', :ec2_block_device_mapping_ephemeral1 => nil, :ec2_block_device_mapping_ephemeral2 => nil, :ec2_block_device_mapping_ephemeral3 => nil } }

      it { should contain_mount('/data') }
    end
  end

  context "two disk" do
    context "ephemeral disk" do
      let(:facts) { { :ec2_instance_type => 'm1.large', :ec2_block_device_mapping_ephemeral0 => '/dev/sdb', :ec2_block_device_mapping_ephemeral1 => '/dev/sdc', :ec2_block_device_mapping_ephemeral2 => nil, :ec2_block_device_mapping_ephemeral3 => nil } }

      it { should contain_exec('create-raid').with_command("mdadm --create --run /dev/md0 --metadata=1.2 --level=0 --chunk=256 --raid-devices=2 /dev/xvdf /dev/xvdg") }
      it { should contain_exec('create mdadm.conf').with_command("echo 'DEVICE /dev/xvdf /dev/xvdg' > /etc/mdadm.conf ; mdadm --detail --scan >> /etc/mdadm.conf") }
      it { should contain_exec('md0-setra').with_command('/sbin/blockdev --setra 65536 /dev/md0') }
      it { should contain_exec('mkfs.xfs-md0').with_command('/sbin/mkfs.xfs -f /dev/md0') }
      it { should contain_mount('/data') }
    end
  end
end
