# Configuration file for logging
LOG_DIR=${WEEK2_LOG_DIR_ENV:-"/var/log/system-monitor"}
LOG_FILE="${LOG_DIR}/system-status.log"

# Log to file and journald
log_info() {
    local message=$1
    ENV_NAME="${2}_LOG_FILE"
    ENV_VALUE="${!ENV_NAME}"
    echo "$ENV_VALUE file"
    echo -e  "\t$(get_current_time) - $message" >> "${ENV_VALUE:-LOG_FILE}"
    echo "$message" | systemd-cat -p info -t "$(echo ${ENV_NAME} | tr '_' '-' | tr '[:lower:]' '[:upper:]')"
}