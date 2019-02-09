#!/usr/bin/bash

#
# --without-reduce --without-ocf
#

./configure     --enable-debug --disable-tests \
                --without-fio \
                --without-vhost --without-virtio --without-pmdk \
                --without-vpp --without-rbd \
                --with-rdma \
                --without-iscsi-initiator --without-vtune \
                --without-reduce --without-ocf
