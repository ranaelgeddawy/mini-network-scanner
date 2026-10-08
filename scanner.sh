#!/bin/bash

# =============================================
# Mini Network Scanner - scanner.sh
# =============================================

read -p "Enter target IP or hostname:  " TARGET

if [ -z "$TARGET" ]; then
    echo "No target provided. Exiting."
    exit 1
fi


echo -n "Check reachability..."
ping -c 1 -W 1 "$TARGET" &>/dev/null 

if [ $? -ne 0 ]; then
	echo "Target Unreachable."
	exit 1
fi
echo "Reachable!"

read -p "Enter port range (e.g. 1-100): " PORT_RANGE 

START_PORT=$(echo "$PORT_RANGE" | cut -d'-' -f1)
END_PORT=$(echo "$PORT_RANGE" | cut -d'-' -f2)

if ! [[ "$START_PORT" =~ ^[0-9]+$ ]] || ! [[ "$END_PORT" =~ ^[0-9]+$ ]]; then
    echo "Invalid port range. Use format: START-END (e.g. 1-100)"
    exit 1
fi

declare -A SERVICES=(
	[21]="FTP"
	[22]="SSH"
	[23]="Telnet"
	[25]="SMTP"
	[53]="DNS"
	[80]="HTTP"
	[110]="POP3"
	[143]="IMAP"
	[443]="HTTPS"
	[3306]="MySQL"
	[3389]="RDP"
	[8080]="HTTP-Alt"
)

START_TIME=$(date +%s)

mkdir -p Reports 
rm -f "Reports/scan_${TARGET}"*.txt
REPORT_FILE="Reports/scan_${TARGET}.txt"

report() {
	echo "$1" | tee -a "$REPORT_FILE"
}

report "================================="
report "Mini Network Scanner"
report "================================="
report ""
report "Target: $TARGET"
report "Status: Reachable"
report "Port Range: $PORT_RANGE"
report ""
report "PORT    STATE   SERVICE"
report "------------------------"

TMP_DIR=$(mktemp -d)

for PORT in $(seq "$START_PORT" "$END_PORT"); do 
	(
		SERVICE="${SERVICES[$PORT]:-Unknown}"
		if timeout 1 bash -c "echo > /dev/tcp/$TARGET/$PORT" 2>/dev/null; then
			STATE="OPEN"
		else 
			STATE="CLOSED"
		fi
		echo "$PORT|$STATE|$SERVICE" > "$TMP_DIR/port_$PORT.txt"
	) &
done 

wait 

for PORT in $(seq "$START_PORT" "$END_PORT"); do 
	if [ -f "$TMP_DIR/port_$PORT.txt" ]; then
		IFS='|' read -r PORT STATE SERVICE < "$TMP_DIR/port_$PORT.txt"
		report "$(printf "%-8s %-8s %s" "$PORT" "$STATE" "$SERVICE")"
        	rm -f "$TMP_DIR/port_$PORT.txt"
	fi
done

rm -rf "$TMP_DIR"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

report ""
report "Scan completed in $DURATION seconds"
report "================================="
report "End"
report "================================="

echo ""
echo "Report saved to: $REPORT_FILE"
