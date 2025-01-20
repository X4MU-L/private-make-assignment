# Configuration file for logging
LOG_DIR=${WEEK2_LOG_DIR_ENV:-"/var/log/system-monitor"}
LOG_FILE="${LOG_DIR}/system-status.log"

# Log to file and journald
log_info() {
    local message=$1
    local UPPER_VAR="$(echo ${2} | tr '-' '_' | tr '[:lower:]' '[:upper:]')"
    ENV_NAME="${UPPER_VAR}_LOG_FILE"
    ENV_VALUE="${!ENV_NAME}"
    # echo -e  "\t$(get_current_time) - $message" >> "${ENV_VALUE:-LOG_FILE}"
    echo "$message" | systemd-cat -p info -t "$2"
}