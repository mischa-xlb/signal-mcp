#!/bin/bash
# Signal CLI Setup Script for OCI Code-Server
# This script helps register your phone number with signal-cli

set -e

echo "========================================"
echo "Signal CLI Setup for Code-Server"
echo "========================================"
echo ""

# Check if signal-cli is installed
if ! command -v signal-cli &> /dev/null; then
    echo "Error: signal-cli is not installed"
    echo "Please install signal-cli first: https://github.com/AsamK/signal-cli"
    exit 1
fi

echo "✓ signal-cli is installed (version: $(signal-cli --version))"
echo ""

# Prompt for phone number
read -p "Enter your phone number (with country code, e.g., +1234567890): " PHONE_NUMBER

# Validate phone number format
if [[ ! "$PHONE_NUMBER" =~ ^\+[0-9]{10,15}$ ]]; then
    echo "Error: Invalid phone number format. Must start with + and include country code"
    exit 1
fi

echo ""
echo "Step 1: Registering $PHONE_NUMBER with Signal..."
echo "You will receive an SMS with a verification code."
echo ""

# Use captcha method for registration (more reliable)
echo "Please complete the CAPTCHA challenge:"
echo "1. Open this URL in your browser: https://signalcaptchas.org/registration/generate.html"
echo "2. Complete the CAPTCHA"
echo "3. Copy the signalcaptcha:// URL"
echo ""
read -p "Paste the signalcaptcha:// URL here: " CAPTCHA

if [[ ! "$CAPTCHA" =~ ^signalcaptcha:// ]]; then
    echo "Error: Invalid captcha URL"
    exit 1
fi

echo ""
echo "Registering with Signal..."
signal-cli -u "$PHONE_NUMBER" register --captcha "$CAPTCHA"

echo ""
echo "========================================"
echo "Step 2: Verification"
echo "========================================"
echo "Check your phone for an SMS with a verification code."
echo "The code is usually 6 digits like: 123-456"
echo ""
read -p "Enter the verification code (numbers only, no dashes): " VERIFY_CODE

# Remove any dashes or spaces
VERIFY_CODE=$(echo "$VERIFY_CODE" | tr -d ' -')

if [[ ! "$VERIFY_CODE" =~ ^[0-9]{6}$ ]]; then
    echo "Error: Verification code must be 6 digits"
    exit 1
fi

echo ""
echo "Verifying..."
signal-cli -u "$PHONE_NUMBER" verify "$VERIFY_CODE"

echo ""
echo "✓ Successfully registered $PHONE_NUMBER with Signal!"
echo ""

# Create .env file
echo "Creating .env file for testing..."
cat > .env << EOF
# Signal MCP Configuration
SENDER_NUMBER=$PHONE_NUMBER
RECEIVER_NUMBER=$PHONE_NUMBER
EOF

echo "✓ Created .env file"
echo ""

# Test the setup
echo "Testing signal-cli setup..."
signal-cli -u "$PHONE_NUMBER" receive --timeout 1 &> /dev/null && echo "✓ Signal CLI is working!" || echo "⚠ Warning: Signal CLI test had issues"

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Your phone number: $PHONE_NUMBER"
echo "Configuration saved to: .env"
echo ""
echo "Next steps:"
echo "1. Run './run_bridge.sh' to start the Claude-Signal bridge"
echo "2. Send a message from your phone to test"
echo "3. Use './install_service.sh' to set up automatic startup"
echo ""
echo "To test manually:"
echo "  source venv/bin/activate"
echo "  server --user-id $PHONE_NUMBER --transport stdio"
echo ""
