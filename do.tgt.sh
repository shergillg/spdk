#!/bin/bash

# Transport 1.
T1_TRANS=rdma

T1_IP=192.168.0.16
T1_PORT=4420
T1_NQN=nqn.2025-02.io.spdk:rdma:dl16a

T1_DIP=$IP
T1_DPORT=4420
T1_DNQN=nqn.2014-08.org.nvmexpress.discovery

# Transport 2.
T2_TRANS=tcp

T2_IP=192.168.0.16
T2_PORT=4420
T2_NQN=nqn.2025-02.io.spdk:tcp:dl16a

T2_DIP=$IP
T2_DPORT=8009
T2_DNQN=nqn.2014-08.org.nvmexpress.discovery

MAX_QPS_PER_CTRLR=16

TGT_APP="./build/bin/nvmf_tgt"
TGT_CPU="0x03"
TGT_MEM=1024
TGT_LOG="tgt.log"

RPC="./scripts/rpc.py"

spdk_start_tgt_app() {
    echo "Kill nvmf_tgt app..."
    $RPC spdk_kill_instance SIGTERM

    echo "Starting new nvmf_tgt app..."
    $TGT_APP -m $TGT_CPU -s $TGT_MEM --wait-for-rpc > $TGT_LOG 2>&1 &

    # Following sleep is needed otherwise the rpc calls sometimes don't have any affect.
    sleep 1
    $RPC log_set_level debug
    $RPC log_set_flag nvmf
    $RPC log_set_flag nvmf_tcp
}

spdk_start_transport() {
    FW_INIT=$1

    TRANS=$2
    IP=$3
    PORT=$4
    NQN=$5

    DIP=$6
    DPORT=$7
    DNQN=$8

    # Start subsystem initialization.
    if [[ "$FW_INIT" == "yes" ]]; then
        $RPC framework_start_init
    fi

    # Initialize transport.
    $RPC nvmf_create_transport -t $TRANS -q 128 -m 1 -c 4096 -i 131072 -u 131072 -a 128 -b 32 -n 4096 \
                                            -c $MAX_QPS_PER_CTRLR

    return

    # Discovery subsystem already exists. Add listner for it.
    $RPC nvmf_subsystem_add_listener -t $TRANS -a $DIP -s $DPORT $DNQN

    # Create a subsystem. Let any host access it. Create a listner for it.
    $RPC nvmf_create_subsystem $NQN 
    $RPC nvmf_subsystem_allow_any_host -e $NQN 
    $RPC nvmf_subsystem_add_listener -t $TRANS -a $IP -s $PORT $NQN

    # Create a NULL BDEV and add it as NS to above subsystem.
    NBD_NAME_A=nbdev_a
    NBD_SZ_A=10240
    NBD_BSZ_A=512

    $RPC bdev_null_create $NBD_NAME_A $NBD_SZ_A $NBD_BSZ_A
    $RPC nvmf_subsystem_add_ns $NQN $NBD_NAME_A
}

spdk_start_tgt_app 

echo "Creating transport $T1_TRANS"
spdk_start_transport "yes" $T1_TRANS $T1_IP $T1_PORT $T1_NQN $T1_DIP $T1_DPORT $T1_DNQN

echo "Creating transport $T2_TRANS"
spdk_start_transport "no" $T2_TRANS $T2_IP $T2_PORT $T2_NQN $T2_DIP $T2_DPORT $T2_DNQN

