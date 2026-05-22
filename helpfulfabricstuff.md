#Helpful one liners and small liners for day to day stuff

# Linux iSCSI MTU Verification (df = do not fragment)
ping -M do -s 8972 <Target_iSCSI_IP>

# ESXi vmkping Equivalent
vmkping -d -s 8972 <Target_iSCSI_IP>

#**Port Validation:** Quickly confirm if the array target ports are listening before touching the host initiator configuration.

bash
nc -zv <Storage_Array_IP> 3260   # Test iSCSI Target Default Port
nc -zv <Storage_Array_IP> 445    # Test SMB/CIFS Target Port
nc -zv <Storage_Array_IP> 2049   # Test NFS Target Port

Stress testing:
fio --name=oltp_simulation \
    --filename=/mnt/san_vol/testfile.dat \
    --rw=randrw \
    --rwmixread=70 \
    --bs=8k \
    --ioengine=libaio \
    --iodepth=64 \
    --size=10G \
    --runtime=60 \
    --time_based \
    --group_reporting

# Pull enterprise NVMe drive specific metrics (including health and TBW)
smartctl -a /dev/nvme0n1

# Run an immediate internal drive self-test background routine
smartctl -t short /dev/sda

# I always forget this command for checking multipath mismatch
multipath -ll
