#!/bin/bash

# Transport 1.
T1_TRANS=rdma

T1_IP=192.168.0.16
T1_PORT=4420
T1_NQN=nqn.2025-02.io.spdk:rdma:dl16a

T1_DIP=$T1_IP
T1_DPORT=4420
T1_DNQN=nqn.2014-08.org.nvmexpress.discovery

# Transport 2.
T2_TRANS=tcp

T2_IP=192.168.0.16
T2_PORT=4420
T2_NQN=nqn.2025-02.io.spdk:tcp:dl16a

T2_DIP=$T2_IP
T2_DPORT=8009
T2_DNQN="nqn.2014-08.org.nvmexpress.discovery"

MAX_IO_QP=2
MAX_QD=128
MAX_QD_AQ=32
MAX_IO_SZ=262144
IO_UNIT_SZ=131072
NUM_SH_BUF=1024

TGT_APP="./build/bin/nvmf_tgt"
TGT_CPU="0x0f"
TGT_MEM=3072
TGT_LOG="tgt.log"

RPC="./scripts/rpc.py"

spdk_start_tgt_app() {
    pgrep -f nvmf_tgt
    status=$?
    if [ $status -eq 0 ]; then
        echo "Kill nvmf_tgt app..."
        $RPC spdk_kill_instance SIGTERM
        sleep 1
    fi

    echo "Starting new nvmf_tgt app..."
    $TGT_APP -m $TGT_CPU -s $TGT_MEM --wait-for-rpc > $TGT_LOG 2>&1 &

    # Following sleep is needed otherwise the rpc calls sometimes don't have any affect.
    sleep 1

    echo "Setting up debug level and module flags..."
    $RPC log_set_level debug
    $RPC log_set_flag nvmf
    $RPC log_set_flag nvmf_tcp

    # Init the framework now.
    echo "Doing framework init.."
    $RPC framework_start_init
    sleep 1
}

spdk_start_transport() {
    TRANS=$1
    IP=$2
    PORT=$3
    NQN=$4

    DIP=$5
    DPORT=$6
    DNQN=$7

    # Initialize transport.
    $RPC nvmf_create_transport -t $TRANS -q $MAX_QD -m $MAX_IO_QP \
            -i $MAX_IO_SZ -u $IO_UNIT_SZ -a $MAX_QD_AQ -n $NUM_SH_BUF

    # Discovery subsystem already exists. Add listner for it.
    echo "Adding listner for $DNQN.."
    $RPC nvmf_subsystem_add_listener -t $TRANS -a $DIP -s $DPORT $DNQN

    return

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

# echo "Creating transport $T1_TRANS"
# spdk_start_transport $T1_TRANS $T1_IP $T1_PORT $T1_NQN $T1_DIP $T1_DPORT $T1_DNQN

echo "Creating transport $T2_TRANS"
spdk_start_transport $T2_TRANS $T2_IP $T2_PORT $T2_NQN $T2_DIP $T2_DPORT $T2_DNQN

