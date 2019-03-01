#!/usr/bin/bash

SUB1_NQN=nqn.2019-03.io.spdk:dl08a
SUB1_SN=spdk_dl08a

IP_ADDR=10.2.1.8

# Let's create some bdevs from real nvme devices
./rpc.py construct_nvme_bdev -b sam.p86 -t pcie -a 0000:86:00.0
./rpc.py construct_nvme_bdev -b sam.p87 -t pcie -a 0000:87:00.0
./rpc.py construct_nvme_bdev -b int.p88 -t pcie -a 0000:88:00.0
./rpc.py construct_nvme_bdev -b int.p89 -t pcie -a 0000:89:00.0

# instantiate rdma transport.
./rpc.py nvmf_create_transport -t rdma

# -a to allow all hosts.
./rpc.py nvmf_subsystem_create ${SUB1_NQN} -a -s ${SUB1_SN} 

# Let's add some namespaces.
./rpc.py nvmf_subsystem_add_ns ${SUB1_NQN} int.p88 
./rpc.py nvmf_subsystem_add_ns ${SUB1_NQN} int.p89 

# Time to add listener port
./rpc.py nvmf_subsystem_add_listener ${SUB1_NQN} -t rdma -a ${IP_ADDR} -s 4420 
