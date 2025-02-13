#!/bin/bash

LOG_DIR="$(dirname "$0")"
LOG_FILE="$LOG_DIR/app_restart.log"

# List of Tomcat instances
TOMCAT_INSTANCES=(
    "/apps/tomcat1"
    "/apps/tomcat2"
    "/apps/tomcat3"
)

# List of JBoss instances
JBOSS_INSTANCES=(
    "/apps/jboss1"
    "/apps/jboss2"
)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

start_tomcat() {
    for TOMCAT_HOME in "${TOMCAT_INSTANCES[@]}"; do
        log "Starting Tomcat at $TOMCAT_HOME..."
        /bin/sh "$TOMCAT_HOME/bin/startup.sh" >> "$LOG_FILE" 2>&1 &
        sleep 5
        if pgrep -f "$TOMCAT_HOME" > /dev/null; then
            log "Tomcat at $TOMCAT_HOME started successfully."
        else
            log "ERROR: Tomcat at $TOMCAT_HOME failed to start."
        fi
    done
}

stop_tomcat() {
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

start_jboss() {
    for JBOSS_HOME in "${JBOSS_INSTANCES[@]}"; do
        log "Starting JBoss at $JBOSS_HOME..."
        /bin/sh "$JBOSS_HOME/bin/standalone.sh" >> "$LOG_FILE" 2>&1 &
        sleep 5
        if pgrep -f "$JBOSS_HOME" > /dev/null; then
            log "JBoss at $JBOSS_HOME started successfully."
        else
            log "ERROR: JBoss at $JBOSS_HOME failed to start."
        fi
    done
}

stop_jboss() {
    for JBOSS_HOME in "${JBOSS_INSTANCES[@]}"; do
        log "Stopping JBoss at $JBOSS_HOME..."
        /bin/sh "$JBOSS_HOME/bin/jboss-cli.sh" --connect command=:shutdown >> "$LOG_FILE" 2>&1
        for i in {1..15}; do
            if ! pgrep -f "$JBOSS_HOME" > /dev/null; then
                log "JBoss at $JBOSS_HOME stopped successfully."
                break
            fi
            log "Waiting for JBoss at $JBOSS_HOME to stop... ($i)"
            sleep 1
        done
    done
}

case "$1" in
    start)
        stop_tomcat
        stop_jboss
        start_tomcat
        start_jboss
        ;;
    stop)
        stop_tomcat
        stop_jboss
        ;;
    *)
        log "Usage: $0 {start|stop}"
        exit 1
        ;;
esac