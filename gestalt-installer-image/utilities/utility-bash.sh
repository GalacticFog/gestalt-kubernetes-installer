#!/bin/bash

############################################
# Utilities: Index
############################################

# exit_with_error - Prints passed message with [Error] prefix and exits with error code 1
# exit_on_error - If current status is non-0, prints passed message with [Error] prefix and exits with error code 1

# Global variable ${logging_lvl} is used for logging level. Currently supported: debug, info, error(default)
# log_debug - If global variable ${logging_lvl} set up to debug, log passed message with [Debug] prefix
# log_info - If global variable ${logging_lvl} set at least to info, log passed message with [Info] prefix
# log_debug - If global variable ${logging_lvl} set at least to error(default), log passed message with [Error] prefix

############################################
# Utilities: START
############################################

exit_with_error() {
  echo "[Error] $@"
  exit 1
}

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo "[Error] $@"
    exit 1
  fi
}

log_debug () {
  [ "${logging_lvl}" == "debug" ] && echo && echo "[Debug] $@"
}

log_info () {
  [[ "${logging_lvl}" =~ (debug|info) ]] && echo && echo "[Info] $@"
}

log_error () {
  [[ "${logging_lvl}" =~ (debug|info|error) ]] && echo && echo "[Error] $@"
}



############################################
# Utilities: END
############################################