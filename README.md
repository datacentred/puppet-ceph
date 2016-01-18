#Ceph

[![Build Status](https://travis-ci.org/spjmurray/puppet-ceph.png?branch=master)](https://travis-ci.org/spjmurray/puppet-ceph)

####Table Of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Usage](#usage)
4. [Limitations](#limitations)

##Overview

Deploys Ceph components

###Module Description

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
can be provisioned with 'Slot 01/Slot 12' which directly correlates with slot names
found in sysfs.  The two addressing modes can be used interchangably thus
configuration like 'Slot 01/2:0:0:0' is permissible.

### Usage

The module is exlusively for use with hiera to segregate data from code thus
all you need in your manifests is:

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
  3:0:0:0/6:0:0:0:
    fstype: 'xfs'
  4:0:0:0/6:0:0:0:
    fstype: 'xfs'
  5:0:0:0/6:0:0:0:
    fstype: 'xfs'
```

It is recommended to enable deep merging so that global configuration can be
defined in common.yaml and role/host specific configuration merged with the
global section.

##Limitations

1. Keys are implicitly added on the monitor, ergo all keys need to be defined
   on the monitor node
2. For use with ceph 0.94 (Hammer) or lower
