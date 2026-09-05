LINE="$(sed -n '/\/dev\/cpuset\/background\/cpus/=' "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh")"
sed -i \
    "$LINE cecho 0-1 > /dev/cpuset/background/cpus\necho 0-3 > /dev/cpuset/restricted/cpus" \
    "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"

# Extreme kernel tweaks - 778G no talo (yupik = SM7325)
LOG_STEP_IN "- Extreme kernel perf tweaks (yupik 778G)"

# schedutil hispeed + WALT
if grep -q "schedutil" "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"; then
    sed -i "s/echo schedutil >.*/\0\n    echo 500 > \/sys\/devices\/system\/cpu\/cpufreq\/schedutil\/rate_limit_us/" "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh" || true
fi

# GPU kgsl 305-845MHz
echo "echo 305000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
echo "echo 845000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"

# zRAM lz4 + swappiness + reclaim
echo "echo lz4 > /sys/block/zram0/comp_algorithm" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
echo "echo 3G > /sys/block/zram0/disksize" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
echo "mkswap /dev/block/zram0; swapon /dev/block/zram0 -p 32758" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
echo "echo 150 > /proc/sys/vm/swappiness" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
echo "echo 1 > /proc/sys/vm/compact_memory" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"

# i/o maple + readahead
echo "echo maple > /sys/block/sda/queue/scheduler" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"
echo "echo 1024 > /sys/block/sda/queue/read_ahead_kb" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"

# tcp bbr
echo "sysctl -w net.ipv4.tcp_congestion_control=bbr" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"

# thermal headroom +3C (42->45)
if [ -f "$WORK_DIR/vendor/etc/thermal_config.conf" ]; then
    sed -i "s/42000/45000/g" "$WORK_DIR/vendor/etc/thermal_config.conf" || true
fi

# surfaceflinger boost
echo "setprop debug.sf.enable_gl_backpressure 1" >> "$WORK_DIR/vendor/bin/init.kernel.post_boot-yupik.sh"

LOG_STEP_OUT
