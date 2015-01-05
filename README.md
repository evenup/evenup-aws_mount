[![Puppet Forge](http://img.shields.io/puppetforge/v/evenup/aws_mount.svg)](https://forge.puppetlabs.com/evenup/aws_mount)
[![Build Status](https://travis-ci.org/evenup/evenup-aws_mount.png?branch=master)](https://travis-ci.org/evenup/evenup-aws_mount)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with aws_mount](#setup)
    * [What aws_mount affects](#what-aws_mount-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with aws_mount](#beginning-with-aws_mount)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)
8. [Changelog/Contributors](#changelog-contributors)

## Overview

Puppet module to mount AWS EC2 ephemeral disks

## Module Description

This module is designed to automatically mount and create a RAID0 array from any ephemerial disks on AWS instances.

It is recommended to run this module in a stage prior to 'main' (such as setup if you're using puppetlabs/stdlib) to ensure the volume is available for the rest of your modules.

## Setup

### What aws_mount affects

* All ephemerial disks

### Setup Requirements

* mdadm
* xfs
* trusted_node_data = true in puppet.conf

### Beginning with aws_mount

To install the evenup-aws_mount module:

```
    puppet module install evenup-aws_mount
```

## Usage

To mount the disks:

```puppet
  class {'aws_mount': }
```

## Reference

### Class `aws_mount`

#### Parameters

#####`mount_point`

String.  Location the volume should be mounted

## Limitations

* 8 and 24 disks not currently supported

## Development

Improvements and bug fixes are greatly appreciated.  See the [contributing guide](https://github.com/evenup/evenup-aws_mount/blob/master/CONTRIBUTING.md) for
information on adding and validating tests for PRs.

## Changelog / Contributors

[Changelog](https://github.com/evenup/evenup-aws_mount/blob/master/CHANGELOG)
[Contributors](https://github.com/evenup/aws_mount/graphs/contributors)
