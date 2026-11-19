# Adapted from the Snapdragon Galaxy S20 FE Android 16 refresh-rate patch.
# A52s exposes 60 Hz and 120 Hz modes in config.sh.
IDLE_TIMER_MS=200
TOUCH_TIMER_MS=300

SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
LOG "Adding SurfaceFlinger idle timer ($IDLE_TIMER_MS ms)"
EVAL "sed -i \"/use_content_detection_for_refresh_rate/a ro.surface_flinger.set_idle_timer_ms=$IDLE_TIMER_MS\" \"$WORK_DIR/vendor/default.prop\""
LOG "Adding SurfaceFlinger touch timer ($TOUCH_TIMER_MS ms)"
EVAL "sed -i \"/set_idle_timer_ms/a ro.surface_flinger.set_touch_timer_ms=$TOUCH_TIMER_MS\" \"$WORK_DIR/vendor/default.prop\""
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"

unset IDLE_TIMER_MS TOUCH_TIMER_MS
