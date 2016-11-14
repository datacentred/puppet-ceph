# Ceph

[![Build Status](https://travis-ci.org/spjmurray/puppet-ceph.png?branch=master)](https://travis-ci.org/spjmurray/puppet-ceph)

#### Table Of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Compatibility Matrix](#compatibility-matrix)
4. [Setup - The basics of getting started with ceph](#setup)
    * [Setup Requirements](#setup-requirements)
5. [Usage](#usage)
    * [Basic Usage](#basic-usage)
    * [Advanced Usage](#advanced-usage)
6. [Limitations](#limitations)

## Overview

Deploys Ceph components

## Module Description

Very lightweight implementation of Ceph deployment.  This module depends quite
heavily on knowledge of how the various ceph commands work and the requisite
configuration values. See the usage example below.

The osd custom type operates on SCSI addresses e.g. '1:0:0:0/6:0:0:0'.  This
aims to solve the problem when a disk is removed from the cluster and replaced.
The device node name is liable to change from /dev/sdb to /dev/sde thus hard
coding device names is bad.  However if we model deployment on hardware location
then we can derive the device name, probe the drive partiton type and provision
based on whether ceph-disk has been run.

The OSD provider can also operate on enclosures with SES firmware running on
a SAS expander.  In some cases SCSI addresses aren't predicatable and susceptible
to the same enumeration problem as /dev device names.  In these cases the devices
can be provisioned with 'Slot 01' which directly correlates to a slot name
found in sysfs under /sys/class/enclosure.  On newer expanders the labels may be
formatted as DISK00 which is also supported.  The two addressing modes can be used
interchangably.

The OSD provider also accepts an arbitrary hash of parameters to be passed to
ceph-disk.  The keys are the long options supported by ceph-disk stripped of the
leading double hyphens.  Values are either strings or nil/undef e.g. for options
without arguments like --bluestore.

## Compatibility Matrix

| Version | Operating System                       | Ceph | Puppet |
| ------- | -------------------------------------- | -----| ------ |
| 1.0.x   | Ubuntu 14.04                           | 0.94 | 3      |
| 1.1.x   | Ubuntu 14.04                           | 0.94 | 3      |
| 1.2.x   | Ubuntu 14.04                           | 0.94 | 3      |
| 1.3.x   | Ubuntu 14.04, Centos 7                 | 0.94 | 3      |
| 1.4.x   | Ubuntu 14.04, Centos 7                 | 9    | 3, 4   |
| 1.5.x   | Ubuntu 14.04, Ubuntu 16.04\*, Centos 7 | 10   | 3, 4   |

\* Ubuntu 16.04 only tested with Puppet 4

## Setup

### Setup Requirements

Paths to binaries executed by this module are relative, so you will need to include
the following snippet, typically in manifests/site.pp, in order to execute the
generated catalog:

```puppet
Exec {
  path => '/bin:/usr/bin:/sbin:/usr/sbin',
}
```

## Usage

### Basic Usage

To create a simple all in one server for test and development work:

```puppet
include ::ceph
```

Hiera data should look like the following:

```yaml
---
# Deployment options
ceph::mon: true
ceph::osd: true

# Install options
ceph::manage_repo: true
ceph::repo_version: 'giant'

# ceph.conf
ceph::conf:
  global:
    fsid: '62ed9bd6-adf4-11e4-8fb5-3c970ebb2b86'
    mon_initial_members: "%{hostname}"
    mon_host: "%{ipaddress_eth0}"
    public_network: "%{network_eth0}/24"
    cluster_network: "%{network_eth1}/24"
    auth_supported: 'cephx'
    filestore_xattr_use_omap: 'true'
    osd_crush_chooseleaf_type: '0'
  osd:
    osd_journal_size: '1000'

# Create these keyrings on the monitors
ceph::keys:
  /etc/ceph/ceph.client.admin.keyring:
    user: 'client.admin'
    key: 'AQBAyNlUmO09CxAA2u2p6s38wKkBXaLWFeD7bA=='
    caps_mon: 'allow *'
    caps_osd: 'allow *'
    caps_mds: 'allow'
  /var/lib/ceph/bootstrap-osd/ceph.keyring:
    user: 'client.bootstrap-osd'
    key: 'AQDLGtpUdYopJxAAnUZHBu0zuI0IEVKTrzmaGg=='
    caps_mon: 'allow profile bootstrap-osd'
  /var/lib/ceph/bootstrap-mds/ceph.keyring:
    user: 'client.bootstrap-mds'
    key: 'AQDLGtpUlWDNMRAAVyjXjppZXkEmULAl93MbHQ=='
    caps_mon: 'allow profile bootstrap-mds'

# Create the OSDs
ceph::disks:
  3:0:0:0:
    journal: '6:0:0:0'
    params:
      fs-type: 'xfs'
  4:0:0:0:
    journal: '6:0:0:0'
    params:
      fs-type: 'xfs'
  5:0:0:0:
    journal: '6:0:0:0'
    params:
      fs-type: 'xfs'
```

### Advanced Usage

It is recommended to enable deep merging so that global configuration can be
defined in common.yaml and role/host specific configuration merged with the
global section.  A typical production deployment may look similar to the
following:

```yaml
---
### /var/lib/hiera/module/ceph.yaml

# Merge configuration based on role
ceph::conf_merge: true

# Global configuration for all nodes
ceph::conf:
  global:
    fsid: '62ed9bd6-adf4-11e4-8fb5-3c970ebb2b86'
    mon initial members: 'mon0,mon1,mon2'
    mon host: '10.0.0.2,10.0.0.3,10.0.0.4'
    auth supported: 'cephx'
    public network: '10.0.0.0/16'
    cluster network: '10.0.0.0/16'

# Merge keys based on role
ceph::keys_merge: true
```

```yaml
---
### /var/lib/hiera/role/ceph-mon.yaml

# Install a monitor
ceph::mon: true

# Monitor specific configuration
ceph::conf:
  mon:
    mon compact on start: 'true'
    mon compact on trim: 'true'

# All the static keys on the system
ceph::keys:
  /etc/ceph/ceph.client.admin.keyring:
    user: 'client.admin'
    key: "%{hiera('ceph_key_client_admin')}"
    caps_mon: 'allow *'
    caps_osd: 'allow *'
    caps_mds: 'allow'
  /var/lib/ceph/bootstrap-osd/ceph.keyring:
    user: 'client.bootstrap-osd'
    key: "%{hiera('ceph_key_bootstrap_osd')}"
    caps_mon: 'allow profile bootstrap-osd'
  /var/lib/ceph/bootstrap-mds/ceph.keyring:
    user: 'client.bootstrap-mds'
    key: "%{hiera('ceph_key_bootstrap_mds')}"
    caps_mon: 'allow profile bootstrap-mds'
  /etc/ceph/ceph.client.radosgw.rgw0.keyring:
    user: 'client.radosgw.rgw0'
    key: "%{hiera('ceph_key_client_radosgw_rgw0')}"
    caps_mon: 'allow rwx'
    caps_osd: 'allow rwx'
  /etc/ceph/ceph.client.glance.keyring:
    user: 'client.glance'
    key: "%{hiera('ceph_key_client_glance')}"
    caps_mon: 'allow r'
    caps_osd: 'allow class-read object_prefix rbd_children, allow rwx pool=glance'
  /etc/ceph/ceph.client.cinder.keyring:
    user: 'client.cinder'
    key: "%{hiera('ceph_key_client_cinder')}"
    caps_mon: 'allow r'
    caps_osd: 'allow class-read object_prefix rbd_children, allow rx pool=glance, allow rwx pool=cinder'
```

```yaml
---
### /var/lib/hiera/role/ceph-osd.yaml

# Create OSDs
ceph::osd: true

# OSD specific configuration
ceph::conf:
  osd:
    filestore xattr use omap: 'true'
    osd journal size: '10000'
    osd mount options xfs: 'noatime,inode64,logbsize=256k,logbufs=8'
    osd crush location hook: '/usr/local/bin/location_hook.py'
    osd recovery max active: '1'
    osd max backfills: '1'
    osd recovery threads: '1'
    osd recovery op priority: '1'

# OSD specific static keys
ceph::keys:
  /etc/ceph/ceph.client.admin.keyring:
    user: 'client.admin'
    key: "%{hiera('ceph_key_client_admin')}"
  /var/lib/ceph/bootstrap-osd/ceph.keyring:
    user: 'client.bootstrap-osd'
    key: "%{hiera('ceph_key_bootstrap_osd')}"
```

```yaml
---
### /var/lib/hiera/productname/X10DRC-LN4+.yaml

# Product specific OSD definitions
ceph::disks:
  Slot 01:
    journal: 'Slot 01'
  Slot 02:
    journal: 'Slot 02'
  Slot 03:
    journal: 'Slot 03'
  Slot 04:
    journal: 'Slot 04'
  Slot 05:
    journal: 'Slot 05'
  Slot 06:
    journal: 'Slot 06'
  Slot 07:
    journal: 'Slot 07'
  Slot 08:
    journal: 'Slot 08'
  Slot 09:
    journal: 'Slot 09'
  Slot 10:
    journal: 'Slot 10'
  Slot 11:
    journal: 'Slot 11'
  Slot 12:
    journal: 'Slot 12'
```

```yaml
---
### /var/lib/hiera/role/ceph-rgw.yaml

# Create a Rados gateway
ceph::rgw: true
ceph::rgw_id: "radosgw.%{hostname}"

# Rados gateway specific configuration
ceph::conf:
  client.radosgw.%{hostname}:
    host: "%{hostname}"
    keyring: "/etc/ceph/ceph.client.radosgw.%{hostname}.keyring"
    rgw enable usage log: 'true'
    rgw thread pool size: '4096'
    rgw dns name: 'storage.example.com'
    rgw socket path: "/var/run/ceph/ceph.client.radosgw.%{hostname}.fastcgi.sock"
    rgw keystone url: 'https://keystone.example.com:35357'
    rgw keystone admin token: 'dab8928d-1787-4d73-b3e9-1184a4aeffcb'
    rgw keystone accepted roles: '_member_,admin'
    rgw relaxed s3 bucket names: 'true'

# Rados gateway specific static keys
ceph::keys:
  /etc/ceph/ceph.client.admin.keyring:
    user: 'client.admin'
    key: "%{hiera('ceph_key_client_admin')}"
```

```yaml
---
### /var/lib/hiera/node/rgw0.yaml

# Rados gateway node specific configuration
ceph::keys:
  /etc/ceph/ceph.client.radosgw.rgw0.keyring:
    user: 'client.radosgw.rgw0'
    key: "%{hiera('ceph_key_client_radosgw_rgw0')}"
```

```yaml
---
### /var/lib/hiera/role/openstack-controller.yaml

# OpenStack controller specific static keys
ceph::keys:
  /etc/ceph/ceph.client.cinder.keyring:
    user: 'client.cinder'
    key: "%{hiera('ceph_key_client_cinder')}"
  /etc/ceph/ceph.client.glance.keyring:
    user: 'client.glance'
    key: "%{hiera('ceph_key_client_glance')}"
```

```yaml
---
### /var/lib/hiera/role/openstack-compute.yaml

# OpenStack compute specific configuration
ceph::conf:
  client:
    rbd cache: 'true'
    rbd cache size: '268435456'
    rbd cache max dirty: '201326592'
    rbd cache dirty target: '134217728'
    rbd cache max dirty age: '2'
    rbd cache writethrough until flush: 'true'

# OpenStack compute specific static keys
ceph::keys:
  /etc/ceph/ceph.client.cinder.keyring:
    user: 'client.cinder'
    key: "%{hiera('ceph_key_client_cinder')}"
```

## Limitations

1. Keys are implicitly added on the monitor, ergo all keys need to be defined
   on the monitor node
