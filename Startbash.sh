#!/bin/bash

LOG_DIR="$(dirname "$0")"
LOG_FILE="$LOG_DIR/app_restart.log"

# List of Tomcat instances
TOMCAT_INSTANCES=(
  "/apps/bweb/apps/tomcat/bbbbb/"
  "/apps/bweb/apps/tomcat/aaaa/"
  "/apps/bweb/apps/tomcat/ccccc/"
)

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

echo -e "\n\nRunning the Script" >> "$LOG_FILE"

start_tomcat() {
  for TOMCAT_HOME in "${TOMCAT_INSTANCES[@]}"; do
    log "Starting Tomcat at $TOMCAT_HOME..."

    # Clean up stale PID file if it exists and points to no running process
    PID_FILE="$TOMCAT_HOME/tomcat.pid"
    if [[ -f "$PID_FILE" ]]; then
      PID=$(cat "$PID_FILE")
      if ! ps -p "$PID" > /dev/null; then
        log "Stale PID file found at $PID_FILE. Removing it."
        rm -f "$PID_FILE"
      else
        log "WARNING: Process $PID is still running. Skipping start to avoid duplicate instance."
        continue
      fi
    fi

    /bin/sh "$TOMCAT_HOME/bin/startup.sh" >> "$LOG_FILE" 2>&1 &

    # Wait up to 30 seconds for it to come up
    for i in {1..30}; do
      if pgrep -f "$TOMCAT_HOME" > /dev/null; then
        log "Tomcat at $TOMCAT_HOME started successfully."
        break
      fi
      sleep 1
    done

    if ! pgrep -f "$TOMCAT_HOME" > /dev/null; then
      log "ERROR: Tomcat at $TOMCAT_HOME failed to start within timeout."
    fi
  done
}

stop_tomcat() {
  for TOMCAT_HOME in "${TOMCAT_INSTANCES[@]}"; do
    log "Stopping Tomcat at $TOMCAT_HOME..."

    PID_FILE="$TOMCAT_HOME/tomcat.pid"
    if [[ -f "$PID_FILE" ]]; then
      PID=$(cat "$PID_FILE")
      if ! ps -p "$PID" > /dev/null; then
        log "No running process for PID $PID — removing stale PID file."
        rm -f "$PID_FILE"
        continue
      fi
    fi

    /bin/sh "$TOMCAT_HOME/bin/shutdown.sh" >> "$LOG_FILE" 2>&1

    # Wait up to 15 seconds for it to shut down
    for i in {1..15}; do
      if ! pgrep -f "$TOMCAT_HOME" > /dev/null; then
        log "Tomcat at $TOMCAT_HOME stopped successfully."
        break
      fi
      log "Waiting for Tomcat at $TOMCAT_HOME to stop... ($i)"
      sleep 1
    done

    if pgrep -f "$TOMCAT_HOME" > /dev/null; then
      log "WARNING: Tomcat at $TOMCAT_HOME may not have stopped cleanly."
    fi
  done
}

# Main flow (modify as needed)
stop_tomcat
start_tomcat