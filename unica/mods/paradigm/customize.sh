LOG_STEP_IN "- Adding Now Brief"

cat \
"$SRC_DIR/unica/mods/paradigm/SamsungSmartSuggestions/SamsungSmartSuggestions.apk.00" \
"$SRC_DIR/unica/mods/paradigm/SamsungSmartSuggestions/SamsungSmartSuggestions.apk.01" \
"$SRC_DIR/unica/mods/paradigm/SamsungSmartSuggestions/SamsungSmartSuggestions.apk.02" \
"$SRC_DIR/unica/mods/paradigm/SamsungSmartSuggestions/SamsungSmartSuggestions.apk.03" \
"$SRC_DIR/unica/mods/paradigm/SamsungSmartSuggestions/SamsungSmartSuggestions.apk.04" \
> "$WORK_DIR/system/system/priv-app/SamsungSmartSuggestions/SamsungSmartSuggestions.apk"

ADD_TO_WORK_DIR "pa1qxxx" "system" "system/priv-app/Moments/Moments.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/sysconfig/moments.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "pa1qxxx" "system" "system/etc/sysconfig/samsungsmartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION" "20253"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_PERSONALIZED_DATA_CORE" "TRUE"
LOG_STEP_OUT
