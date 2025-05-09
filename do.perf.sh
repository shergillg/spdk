#!/usr/bin/bash

TR="trtype:tcp"
TR+=" adrfam:IPv4"
TR+=" traddr:192.168.0.16"
TR+=" trsvcid:4420"
TR+=" subnqn:nqn.2025-02.io.spdk:tcp:dl16a"
TR+=" hostnqn:nqn.2025-05.io.spdk:dl16i"

SPDK_PERF="./build/bin/spdk_nvme_perf"

CORE_MASK="0x02"
IO_QD=1         # Max IOs outstanding at any point
IO_SZ=2048      # IO size
IO_UNIT_SZ=512  # SGE size
IO_QP=2         # Num IO qpairs
IOPAT="write"   # read, write, randread, randwrite, rw, randrw
IOMIX="50"      # with rw or randrw ... --rwmixread $IOMIX \
HM_SZ="512"     # Hugemem size

TIME="100"      # Intentionally high.
NUM_IOS="2"     # Num IO per thread on each namespace.

LOGFN="perf.log"

echo "Connecting to $TR..."
$SPDK_PERF \
    -r "$TR" \
    --io-depth $IO_QD \
    --io-size $IO_SZ \
    --io-unit-size $IO_UNIT_SZ \
    --num-qpairs $IO_QP \
    --io-pattern $IOPAT \
    --core-mask $CORE_MASK \
    --hugemem-size $HM_SZ \
    --number-ios $NUM_IOS \
    --time $TIME \
    --logflag nvme \
    --transport-stats 2>&1 | tee $LOGFN
    



