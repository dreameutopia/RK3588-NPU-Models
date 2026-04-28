#!/system/bin/sh

echo "=========================================="
echo "RK3588 Performance Optimization Script"
echo "=========================================="
echo ""
echo "This script fixes CPU/NPU/GPU/DDR frequencies"
echo "to maximum values for optimal performance."
echo ""

echo "Disabling CPU idle states..."
echo 1 > /sys/devices/system/cpu/cpu0/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu1/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu2/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu3/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu4/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu5/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu6/cpuidle/state1/disable
echo 1 > /sys/devices/system/cpu/cpu7/cpuidle/state1/disable
echo "Done!"
echo ""

echo "NPU available frequencies:"
cat /sys/class/devfreq/fdab0000.npu/available_frequencies
echo "Fixing NPU max frequency to 1GHz..."
echo userspace > /sys/class/devfreq/fdab0000.npu/governor
echo 1000000000 > /sys/class/devfreq/fdab0000.npu/userspace/set_freq
echo "Current NPU frequency:"
cat /sys/class/devfreq/fdab0000.npu/cur_freq
echo ""

echo "CPU available frequencies:"
echo "Policy0 (Cortex-A55):"
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies
echo "Policy4 (Cortex-A76):"
cat /sys/devices/system/cpu/cpufreq/policy4/scaling_available_frequencies
echo "Policy6 (Cortex-A76):"
cat /sys/devices/system/cpu/cpufreq/policy6/scaling_available_frequencies

echo ""
echo "Fixing CPU max frequencies..."
echo "Policy0 (Cortex-A55) to 1.8GHz..."
echo userspace > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo 1800000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed
echo "Current Policy0 frequency:"
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq

echo "Policy4 (Cortex-A76) to 2.352GHz..."
echo userspace > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
echo 2352000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_setspeed
echo "Current Policy4 frequency:"
cat /sys/devices/system/cpu/cpufreq/policy4/scaling_cur_freq

echo "Policy6 (Cortex-A76) to 2.352GHz..."
echo userspace > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
echo 2352000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_setspeed
echo "Current Policy6 frequency:"
cat /sys/devices/system/cpu/cpufreq/policy6/scaling_cur_freq
echo ""

echo "GPU available frequencies:"
cat /sys/class/devfreq/fb000000.gpu/available_frequencies
echo "Fixing GPU max frequency to 1GHz..."
echo userspace > /sys/class/devfreq/fb000000.gpu/governor
echo 1000000000 > /sys/class/devfreq/fb000000.gpu/userspace/set_freq
echo "Current GPU frequency:"
cat /sys/class/devfreq/fb000000.gpu/cur_freq
echo ""

echo "DDR available frequencies:"
cat /sys/class/devfreq/dmc/available_frequencies
echo "Fixing DDR max frequency to 2.112GHz..."
echo userspace > /sys/class/devfreq/dmc/governor
echo 2112000000 > /sys/class/devfreq/dmc/userspace/set_freq
echo "Current DDR frequency:"
cat /sys/class/devfreq/dmc/cur_freq
echo ""

echo "=========================================="
echo "Performance optimization completed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  NPU: 1.0 GHz"
echo "  GPU: 1.0 GHz"
echo "  CPU Policy0 (A55): 1.8 GHz"
echo "  CPU Policy4 (A76): 2.352 GHz"
echo "  CPU Policy6 (A76): 2.352 GHz"
echo "  DDR: 2.112 GHz"
echo ""
