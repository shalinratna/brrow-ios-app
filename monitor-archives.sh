#!/bin/bash
#
# Archive Monitor - Automatically fixes Xcode archives created from GUI
# This script watches the Xcode Archives directory and automatically adds
# ApplicationProperties to any new archives that don't have them
#
# Usage:
#   Start monitoring: ./monitor-archives.sh start
#   Stop monitoring:  ./monitor-archives.sh stop
#   Check status:     ./monitor-archives.sh status
#

ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ADD_PROPERTIES_SCRIPT="$SCRIPT_DIR/add-archive-properties.sh"
PID_FILE="/tmp/brrow-archive-monitor.pid"
LOG_FILE="/tmp/brrow-archive-monitor.log"

check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "Archive monitor is running (PID: $PID)"
            echo "Log file: $LOG_FILE"
            return 0
        else
            echo "Archive monitor is not running (stale PID file)"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo "Archive monitor is not running"
        return 1
    fi
}

start_monitor() {
    if check_status > /dev/null 2>&1; then
        echo "Archive monitor is already running"
        exit 1
    fi

    echo "Starting archive monitor..."
    echo "Watching: $ARCHIVES_DIR"
    echo "Log file: $LOG_FILE"

    nohup bash -c "
        exec > '$LOG_FILE' 2>&1
        echo '=== Archive Monitor Started at \$(date) ==='
        echo 'Watching: $ARCHIVES_DIR'
        echo ''

        # Function to check and fix archive
        check_archive() {
            local ARCHIVE_PATH=\"\$1\"
            local INFO_PLIST=\"\$ARCHIVE_PATH/Info.plist\"

            # Wait a moment for archive to be fully written
            sleep 2

            # Check if archive has ApplicationProperties
            if /usr/libexec/PlistBuddy -c 'Print :ApplicationProperties' \"\$INFO_PLIST\" &>/dev/null; then
                echo \"\$(date): Archive already has ApplicationProperties: \$ARCHIVE_PATH\"
                return 0
            fi

            echo \"\$(date): Fixing archive: \$ARCHIVE_PATH\"
            '$ADD_PROPERTIES_SCRIPT' \"\$ARCHIVE_PATH\"

            if [ \$? -eq 0 ]; then
                echo \"\$(date): ✅ Successfully fixed archive\"
            else
                echo \"\$(date): ❌ Failed to fix archive\"
            fi
        }

        # Monitor for new archives using fswatch or polling
        if command -v fswatch &>/dev/null; then
            echo 'Using fswatch for monitoring'
            fswatch -0 -e '.*' -i '\.xcarchive$' -r '$ARCHIVES_DIR' | while read -d '' ARCHIVE_PATH; do
                check_archive \"\$ARCHIVE_PATH\"
            done
        else
            echo 'fswatch not available, using polling method'
            echo 'Install fswatch for better performance: brew install fswatch'

            # Polling fallback - check every 5 seconds
            LAST_CHECK=\$(date +%s)
            while true; do
                # Find archives created in the last 10 seconds
                find '$ARCHIVES_DIR' -name '*.xcarchive' -type d -newermt \"@\$LAST_CHECK\" 2>/dev/null | while read ARCHIVE_PATH; do
                    check_archive \"\$ARCHIVE_PATH\"
                done
                LAST_CHECK=\$(date +%s)
                sleep 5
            done
        fi
    " &

    echo $! > "$PID_FILE"
    echo "Archive monitor started successfully (PID: $(cat $PID_FILE))"
    echo "Use '$0 stop' to stop the monitor"
    echo "Use 'tail -f $LOG_FILE' to view logs"
}

stop_monitor() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Archive monitor is not running"
        exit 1
    fi

    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping archive monitor (PID: $PID)..."
        kill $PID
        rm -f "$PID_FILE"
        echo "Archive monitor stopped"
    else
        echo "Archive monitor is not running (removing stale PID file)"
        rm -f "$PID_FILE"
    fi
}

case "$1" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo ""
        echo "Commands:"
        echo "  start  - Start monitoring Xcode archives directory"
        echo "  stop   - Stop the archive monitor"
        echo "  status - Check if monitor is running"
        echo ""
        echo "This script automatically fixes archives created from Xcode GUI"
        echo "by adding ApplicationProperties to make them appear as 'iOS App'"
        exit 1
        ;;
esac
