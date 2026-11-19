# Galaxy A52s 5G (`a52sxq`)

This target uses MintOS's existing Galaxy A52s configuration for the Snapdragon 778G / SM7325 platform. The configuration retains the A52s firmware, partition sizes, 120 Hz display modes, camera setup, Wi-Fi firmware, and device-specific kernel prebuilts.

## Adapted software patches

- `patches/hfr` adapts the Android 16 SurfaceFlinger refresh-rate patch from the Snapdragon Galaxy S20 FE (`r8q`). It uses the A52s-supported 60/120 Hz modes and 200 ms idle / 300 ms touch timers.
- `patches/miscs/system.prop` carries over the S20 FE Android 16 RIL SIM-slot fix for the dual-SIM SM-A528B target.
- The existing A52s audio offload and SM7325 cpuset tuning remain in place.

The S20 FE kernel, camera calibration, display tuning, thermal tables, and partition values are specific to its SM8250 hardware and are intentionally not reused on the SM7325 A52s.
