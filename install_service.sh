#!/bin/bash
# Install Signal Bridge as a systemd service

set -e

cd "$(dirname "$0")"

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Please run ./setup_signal.sh first"
    exit 1
fi

# Load environment
export $(cat .env | grep -v '^#' | xargs)

if [ -z "$SENDER_NUMBER" ]; then
    echo "Error: SENDER_NUMBER not set in .env"
    exit 1
fi

PROJECT_DIR="$(pwd)"
VENV_PYTHON="$PROJECT_DIR/venv/bin/python3"

# Create systemd service file
SERVICE_FILE="/tmp/signal-bridge.service"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Signal-Claude Bridge for Code-Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$VENV_PYTHON $PROJECT_DIR/signal_bridge.py --phone-number $SENDER_NUMBER --workspace /home/ubuntu
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "Created service file at $SERVICE_FILE"
echo ""
echo "To install the service, run these commands:"
echo ""
echo "  sudo cp $SERVICE_FILE /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable signal-bridge"
echo "  sudo systemctl start signal-bridge"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u signal-bridge -f"
echo ""
echo "To stop the service:"
echo "  sudo systemctl stop signal-bridge"
echo ""
echo "Note: The service will automatically start on boot."
echo ""

read -p "Would you like to install the service now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo cp "$SERVICE_FILE" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable signal-bridge
    sudo systemctl start signal-bridge

    echo ""
    echo "✓ Service installed and started!"
    echo ""
    echo "Check status with:"
    echo "  sudo systemctl status signal-bridge"
    echo ""
    echo "View logs with:"
    echo "  sudo journalctl -u signal-bridge -f"
else
    echo "Service file created but not installed."
    echo "You can install it manually using the commands above."
fi
