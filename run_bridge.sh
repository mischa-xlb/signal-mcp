#!/bin/bash
# Convenience script to run the Signal-Claude bridge

set -e

cd "$(dirname "$0")"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found"
    echo "Please run ./setup_signal.sh first"
    exit 1
fi

if [ -z "$SENDER_NUMBER" ]; then
    echo "Error: SENDER_NUMBER not set in .env"
    exit 1
fi

echo "Starting Signal-Claude Bridge..."
echo "Phone number: $SENDER_NUMBER"
echo "Press Ctrl+C to stop"
echo ""

# Use virtual environment python directly
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/venv/bin/python3" "$SCRIPT_DIR/signal_bridge.py" --phone-number "$SENDER_NUMBER" --workspace /home/ubuntu
