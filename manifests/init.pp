# == Class: aws_mount
#
# This class mounts AWS ephemeral disks if available
#  Note: This assumes that the ephemeral disks are assigned directly after the root volume
#
#
# === Examples
#
# * Installation:
#     class { 'aws_mount': mount_point => '/var/data' }
#
#
# === Parameters
#
# [*mount_point*]
#   String. Mount point ephemeral disks should be mounted at.
#
# === Authors
#
# * Justin Lambert <mailto:jlambert@letsevenup.com>
#
class aws_mount(
  $mount_point = '/data'
) {

  package { [ 'mdadm', 'xfsprogs' ]:
    ensure  => installed
  }

  file { $mount_point:
    ensure  => directory,
    mode    => '0755',
  }

  Mount {
    require => File[$mount_point]
  }

  if 'ec2_block_device_mapping_ephemeral0' in $::facts {
    # Thanks RedHat for renaming xen block devices
    $real_disk0 = $::facts['ec2_block_device_mapping_ephemeral0'] ? {
      /sdb/   => '/dev/xvdf',
      /sdc/   => '/dev/xvdg',
      /sdd/   => '/dev/xvdh',
      /sde/   => '/dev/xvdi',
      /sdf/   => '/dev/xvdj',
      /sdg/   => '/dev/xvdk',
      default => false
    }
  } else {
    $real_disk0 = false
  }

  if 'ec2_block_device_mapping_ephemeral1' in $::facts {
    # Thanks RedHat for renaming xen block devices
    $real_disk1 = $::facts['ec2_block_device_mapping_ephemeral1'] ? {
      /sdb/   => '/dev/xvdf',
      /sdc/   => '/dev/xvdg',
      /sdd/   => '/dev/xvdh',
      /sde/   => '/dev/xvdi',
      /sdf/   => '/dev/xvdj',
      /sdg/   => '/dev/xvdk',
      default => false
    }
  } else {
    $real_disk1 = false
  }

  if 'ec2_block_device_mapping_ephemeral2' in $::facts {
    # Thanks RedHat for renaming xen block devices
    $real_disk2 = $::facts['ec2_block_device_mapping_ephemeral2'] ? {
      /sdb/   => '/dev/xvdf',
      /sdc/   => '/dev/xvdg',
      /sdd/   => '/dev/xvdh',
      /sde/   => '/dev/xvdi',
      /sdf/   => '/dev/xvdj',
      /sdg/   => '/dev/xvdk',
      default => false
    }
  } else {
    $real_disk2 = false
  }

  if 'ec2_block_device_mapping_ephemeral3' in $::facts {
    # Thanks RedHat for renaming xen block devices
    $real_disk3 = $::facts['ec2_block_device_mapping_ephemeral3'] ? {
      /sdb/   => '/dev/xvdf',
      /sdc/   => '/dev/xvdg',
      /sdd/   => '/dev/xvdh',
      /sde/   => '/dev/xvdi',
      /sdf/   => '/dev/xvdj',
      /sdg/   => '/dev/xvdk',
      default => false
    }
  } else {
    $real_disk3 = false
  }

  case $::ec2_instance_type {
    '', 't1.micro', 'm3.2xlarge', 'm3.xlarge', 'm3.x2xlarge', 't2.micro', 't2.small', 't2.medium': {
      # Nothing to do - no local disk or instance type not defined for some reason
    }

    # Single ephemeral disk
    'm1.small', 'm1.medium', 'm2.xlarge', 'm2.2xlarge', 'm3.medium', 'm3.large', 'c1.medium', 'cr1.8xlarge', 'g2.2xlarge', 'r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge', 'i2.xlarge': {
      if $real_disk0 {
        mount { $mount_point:
          ensure  => mounted,
          atboot  => true,
          device  => $real_disk0,
          fstype  => 'ext3',
          options => 'noatime',
        }
      }
    } #Single Disk

    # Two disks
    'm1.large', 'm2.4xlarge', 'm3.xlarge', 'm3.2xlarge', 'cc1.4xlarge', 'cg1.4xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'hi1.4xlarge', 'cr1.8xlarge', 'r3.8xlarge', 'i2.2xlarge': {
      if $real_disk0 and $real_disk1 {
        exec { 'create-raid':
          path    => '/bin:/usr/bin:/sbin',
          command => "mdadm --create --run /dev/md0 --metadata=1.2 --level=0 --chunk=256 --raid-devices=2 ${real_disk0} ${real_disk1}",
          creates => '/dev/md0',
          require => Package['mdadm'],
          notify  => [Exec['md0-setra'], Exec['mkfs.xfs-md0']],
        }

        exec { 'create mdadm.conf':
          path    => '/bin:/usr/bin:/sbin',
          command => "echo 'DEVICE ${real_disk0} ${real_disk1}' > /etc/mdadm.conf ; mdadm --detail --scan >> /etc/mdadm.conf",
          creates => '/etc/mdadm.conf',
          require => Exec['create-raid'],
        }

        exec { 'md0-setra':
          path        => '/sbin',
          command     => '/sbin/blockdev --setra 65536 /dev/md0',
          refreshonly => true,
        }

        exec { 'mkfs.xfs-md0':
          path        => '/sbin',
          command     => '/sbin/mkfs.xfs -f /dev/md0',
          refreshonly => true,
        }

        mount { $mount_point:
          ensure  => mounted,
          atboot  => true,
          device  => '/dev/md0',
          fstype  => 'xfs',
          options => 'noatime',
          require => Exec['mkfs.xfs-md0'],
        }
      }
    } # Two disks

    # Four disks
    'm1.xlarge', 'c1.xlarge', 'cc2.8xlarge', 'i2.4xlarge' : {
      if $real_disk0 and $real_disk1 and $real_disk2 and $real_disk3 {
        exec { 'create-raid':
          path    => '/bin:/usr/bin:/sbin',
          command => "mdadm --create --run /dev/md0 --metadata=1.2 --level=0 --chunk=256 --raid-devices=2 ${real_disk0} ${real_disk1} ${real_disk2} ${real_disk3}",
          creates => '/dev/md0',
          require => Package['mdadm'],
          notify  => [Exec['md0-setra'], Exec['mkfs.xfs-md0']],
        }

        exec { 'create mdadm.conf':
          path    => '/bin:/usr/bin:/sbin',
          command => "echo 'DEVICE ${real_disk0} ${real_disk1} ${real_disk2} ${real_disk3}' > /etc/mdadm.conf ; mdadm --detail --scan >> /etc/mdadm.conf",
          creates => '/etc/mdadm.conf',
          require => Exec['create-raid'],
        }

        exec { 'md0-setra':
          path        => '/sbin',
          command     => '/sbin/blockdev --setra 65536 /dev/md0',
          refreshonly => true,
        }

        exec { 'mkfs.xfs-md0':
          path        => '/sbin',
          command     => '/sbin/mkfs.xfs -f /dev/md0',
          refreshonly => true,
        }

        mount { $mount_point:
          ensure  => mounted,
          atboot  => true,
          device  => '/dev/md0',
          fstype  => 'xfs',
          options => 'noatime',
          require => Exec['mkfs.xfs-md0'],
        }
      }
    } # Four disks

    'i2.8xlarge': {
      fail('TODO - Need to write ephemeral mount for this instance type')
    } # 8 disks

    'hs1.8xlarge': {
      fail('TODO - Need to write ephemeral mount for this instance type')
    } # 24 disks

    # If not AWS instance or not defined yet
    default: {
      fail("${::ec2_instance_type} not defined")
    }
  }

  file { "${mount_point}/tmp":
    ensure  => directory,
    mode    => '1777'
  }

}
