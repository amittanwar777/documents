#!/bin/bash

LOG_DIR="$(dirname "$0")"
LOG_FILE="$LOG_DIR/tomcat_restart.log"

# List of Tomcat instances
TOMCAT_INSTANCES=(
    "/apps/tomcat1"
    "/apps/tomcat2"
    "/apps/tomcat3"
)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

start() {
    for TOMCAT_HOME in "${TOMCAT_INSTANCES[@]}"; do
        log "Starting Tomcat at $TOMCAT_HOME..."
        /bin/sh "$TOMCAT_HOME/bin/startup.sh" >> "$LOG_FILE" 2>&1 &
        sleep 5  # Allow time for startup
        if pgrep -f "$TOMCAT_HOME" > /dev/null; then
            log "Tomcat at $TOMCAT_HOME started successfully."
        else
            log "ERROR: Tomcat at $TOMCAT_HOME failed to start."
        fi
    done
}

stop() {
    for TOMCAT_HOME in "${TOMCAT_INSTANCES[@]}"; do
        log "Stopping Tomcat at $TOMCAT_HOME..."
        /bin/sh "$TOMCAT_HOME/bin/shutdown.sh" >> "$LOG_FILE" 2>&1
        for i in {1..15}; do
            if ! pgrep -f "$TOMCAT_HOME" > /dev/null; then
                log "Tomcat at $TOMCAT_HOME stopped successfully."
                break
            fi
            log "Waiting for Tomcat at $TOMCAT_HOME to stop... ($i)"
            sleep 1
        done
    done
}

case "$1" in
    start)
        stop
        start
        ;;
    stop)
        stop
        ;;
    *)
        log "Usage: $0 {start|stop}"
        exit 1
        ;;
esac