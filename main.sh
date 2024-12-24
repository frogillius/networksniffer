#!/bin/bash

# Function to install necessary tools
install_tools() {
    echo "Updating package lists and installing necessary tools..."
    if [ -f /etc/redhat-release ]; then
        # For Fedora
        sudo dnf install -y wireshark-cli jq
    elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
        # For Ubuntu/Debian
        sudo apt update
        sudo apt install -y tshark jq
    else
        echo "Unsupported OS. Only Fedora and Ubuntu/Debian are supported."
        exit 1
    fi
    echo "Installation complete!"
}

# Function to log captured traffic
start_logging() {
    echo "Starting network traffic capture..."

    # Set output files
    LOG_FILE="traffic.log"
    JSON_FILE="traffic.json"

    # Clear old logs
    > "$LOG_FILE"
    > "$JSON_FILE"

    echo "Logs will be saved to:"
    echo "  - Text log: $LOG_FILE"
    echo "  - JSON log: $JSON_FILE"

    # Run tshark to capture traffic
    tshark -i any -T fields -e frame.time -e ip.src -e ip.dst -e http.host -e dns.qry.name 2>/dev/null | while read -r line; do
        # Extract fields
        TIMESTAMP=$(echo "$line" | awk '{print $1" "$2}')
        SRC_IP=$(echo "$line" | awk '{print $3}')
        DST_IP=$(echo "$line" | awk '{print $4}')
        DOMAIN=$(echo "$line" | awk '{print $5}')

        # Log to console
        echo "[${TIMESTAMP}] Source: $SRC_IP -> Destination: $DST_IP -> Domain: $DOMAIN" | tee -a "$LOG_FILE"

        # Append to JSON log
        jq -n \
            --arg timestamp "$TIMESTAMP" \
            --arg src_ip "$SRC_IP" \
            --arg dst_ip "$DST_IP" \
            --arg domain "$DOMAIN" \
            '{timestamp: $timestamp, src_ip: $src_ip, dst_ip: $dst_ip, domain: $domain}' >> "$JSON_FILE"
    done
}

# Main script
main() {
    install_tools
    start_logging
}

# Run the main function
main
