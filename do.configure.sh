echo "Doing clean."
make clean

echo "Doing configure."
./configure --enable-tests            \
            --enable-debug            \
            --enable-unit-tests       \
            --enable-examples         \
            --enable-apps             \
            --with-rdma               \
            --with-vfio-user          \
                                      \
            --without-dpdk-uadk       \
            --without-fc              \
            --without-xnvme           \
            --without-crypto          \
            --without-fio             \
            --without-fuse            \
            --without-fuzzer          \
            --without-idxd            \
            --without-iscsi-initiator \
            --without-ocf             \
            --without-vbdev-compress  \
            --without-dpdk-compressdev \
            --without-raid5f          \
            --without-rbd             \
            --without-nvme-cuse       \
            --without-uring           \
            --without-uring-zns       \
            --without-wpdk            \
            --without-daos            \
            --without-shared          \
            --without-virtio          \
            --without-vhost           \
            --without-vtune           \
            --without-sma             \
            --without-avahi           \
            --without-golang          \
            --without-aio-fsdev       \
            --without-usdt            \

if [[ $? -ne 0 ]]; then
    echo "Error in configure."
    exit
fi

echo "Doing make."
make
