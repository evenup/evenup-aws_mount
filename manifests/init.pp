# == Class: aws_mount
#
# This class mounts AWS ephemeral disks if available
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

  Class['aws_mount'] { stage => 'pre' }

  package { [ 'mdadm', 'xfsprogs' ]:
    ensure  => installed
  }

  file { $mount_point:
    ensure  => directory,
    mode    => '0755',
  }

  file { "${mount_point}/tmp":
    ensure  => directory,
    mode    => '1777'
  }

  Mount {
    require => File[$mount_point]
  }

  case $::ec2_instance_type {
    'm3.2xlarge', 'm3.xlarge', 't1.micro': {
      # Nothing to do - no local disk
    }

    # Single ephemeral disk
    'm1.small', 'm1.medium', 'm2.xlarge', 'm2.2xlarge', 'c1.medium', 'cr1.8xlarge': {

      # Thanks RedHat for renaming xen block devices
      $real_disk0 = $::ec2_block_device_mapping_ephemeral0 ? {
        /sdb/  => '/dev/xvdf',
        /sdc/  => '/dev/xvdg',
        /sdd/  => '/dev/xvdh',
        /sde/  => '/dev/xvdf',
        default     => ''
      }

      if $real_disk0 != '' {
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
    'm1.large', 'cc1.4xlarge', 'cg1.4xlarge', 'hi1.4xlarge', 'm2.4xlarge': {
      # Thanks RedHat for renaming xen block devices
      $real_disk0 = $::ec2_block_device_mapping_ephemeral0 ? {
        /sdb/  => '/dev/xvdf',
        /sdc/  => '/dev/xvdg',
        /sdd/  => '/dev/xvdh',
        /sde/  => '/dev/xvdf',
        /sdf/  => '/dev/xvdg',
        /sdg/  => '/dev/xvdh',
        default     => ''
      }

      # Thanks RedHat for renaming xen block devices
      $real_disk1 = $::ec2_block_device_mapping_ephemeral1 ? {
        /sdb/  => '/dev/xvdf',
        /sdc/  => '/dev/xvdg',
        /sdd/  => '/dev/xvdh',
        /sde/  => '/dev/xvdf',
        /sdf/  => '/dev/xvdg',
        /sdg/  => '/dev/xvdh',
        default     => ''
      }

      if $real_disk0 != '' and $real_disk1 != '' {

        exec { 'create-raid':
          path    => "/bin:/usr/bin:/sbin",
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

    'm1.xlarge', 'c1.xlarge', 'cc2.8xlarge' : {
      fail('TODO - Need to write ephemeral mount for this instance type')
    } # Four disks

    'hs1.8xlarge': {
      fail('TODO - Need to write ephemeral mount for this instance type')
    } # 24 disks

    default: {} # If not AWS instance or not defined yet
  }
}
