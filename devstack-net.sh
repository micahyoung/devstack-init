#!/bin/bash

virsh attach-interface devstack-0 network bosh --mac de:ad:be:ef:00:02 --model virtio
