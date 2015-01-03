require 'spec_helper'

describe 'aws_mount', :type => :class do
  let(:facts) { { :ec2_instance_type => 'm1.small', :facts => { 'ec2_block_device_mapping_ephemeral0' => '/dev/sdb' } } }

  it { should create_class('aws_mount') }

  context "all instance types" do
    it { should contain_package('mdadm') }
    it { should contain_package('xfsprogs') }

    it { should contain_file('/data') }
    it { should contain_file('/data/tmp').with_mode('1777') }
  end

  context "no ephemeral" do
    let(:facts) { { :ec2_instance_type => 'm1.small', :facts => {} } }

    it { should_not contain_mount('/data') }
  end

  context "set mount_point" do
    let(:params) { { :mount_point => '/somewhere' } }
#    it { should contain_file('/somewhere') }
#    it { should contain_file('/somewhere/tmp') }
  end

  context "no disks instance" do
    let(:facts) { { :ec2_instance_type => 'm3.2xlarge', :facts => {} } }
    it { should_not contain_mount('/data') }
  end

  context "single ephemeral disk" do
    let(:facts) { { :ec2_instance_type => 'm1.small', :facts => { 'ec2_block_device_mapping_ephemeral0' => '/dev/sdb' } } }

    it { should contain_mount('/data') }
  end

  context "two disk" do
    context "ephemeral disk" do
      let(:facts) { { :ec2_instance_type => 'm1.large', :facts => { 'ec2_block_device_mapping_ephemeral0' => '/dev/sdb', 'ec2_block_device_mapping_ephemeral1' => '/dev/sdc' } } }

      it { should contain_exec('create-raid').with_command("mdadm --create --run /dev/md0 --metadata=1.2 --level=0 --chunk=256 --raid-devices=2 /dev/xvdf /dev/xvdg") }
      it { should contain_exec('create mdadm.conf').with_command("echo 'DEVICE /dev/xvdf /dev/xvdg' > /etc/mdadm.conf ; mdadm --detail --scan >> /etc/mdadm.conf") }
      it { should contain_exec('md0-setra').with_command('/sbin/blockdev --setra 65536 /dev/md0') }
      it { should contain_exec('mkfs.xfs-md0').with_command('/sbin/mkfs.xfs -f /dev/md0') }
      it { should contain_mount('/data') }
    end
  end
end
