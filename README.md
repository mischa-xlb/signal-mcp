# Signal MCP

An [MCP](https://github.com/mcp-signal/mcp) integration for [signal-cli](https://github.com/AsamK/signal-cli) that allows AI agents to send and receive Signal messages.

**Perfect for**: Chat with Claude via Signal on your phone while working in your OCI-hosted code-server!

## Features

- 📱 Send messages to Signal users
- 👥 Send messages to Signal groups
- 📥 Receive and parse incoming messages
- ⚡ Async support with timeout handling
- 📊 Detailed logging
- 🤖 Signal-Claude Bridge for interactive chat via your phone

## Quick Start for OCI Code-Server

This setup lets you chat with Claude via Signal messages on your phone while working in your remote code-server.

### Step 1: One-Command Setup

```bash
./setup_signal.sh
```

This interactive script will:
1. Help you register your phone number with Signal
2. Verify your registration via SMS code
3. Create the necessary configuration files

**Note**: You'll need to complete a CAPTCHA at [signalcaptchas.org](https://signalcaptchas.org/registration/generate.html) during registration.

### Step 2: Start the Bridge

**Option A: Run manually (for testing)**
```bash
./run_bridge.sh
```

**Option B: Install as a service (runs automatically)**
```bash
./install_service.sh
```

### Step 3: Chat with Claude via Signal!

Send a message from your phone to the number you registered. Try these commands:

- `/help` - Show available commands
- `/status` - Check bridge status
- `/ls` - List files in your workspace
- `/pwd` - Show current directory
- `/save filename.txt Hello world` - Save content to a file

Or just send any message to interact with the bridge!

## Prerequisites

### Required Software

1. **signal-cli** (already installed ✓)
   - Version: 0.13.23
   - Location: `/usr/local/bin/signal-cli`

2. **Python 3.13+** (already installed ✓)
   - Virtual environment already set up

3. **A Signal account on your phone**
   - You'll need a phone number to receive SMS verification codes
   - The Signal app should be installed on your phone

## Manual Installation

If you prefer manual setup:

### 1. Install Python Dependencies

```bash
# Activate virtual environment
source venv/bin/activate

# Install the package
pip install -e .

# Install optional dependencies
pip install pytest>=7.0.0 mypy>=1.15.0 ruff>=0.11.2
```

### 2. Register with Signal

```bash
# Get a CAPTCHA from https://signalcaptchas.org/registration/generate.html
signal-cli -u +YOUR_PHONE_NUMBER register --captcha "signalcaptcha://..."

# Verify with SMS code
signal-cli -u +YOUR_PHONE_NUMBER verify 123456
```

### 3. Create Configuration

```bash
# Create .env file
cat > .env << EOF
SENDER_NUMBER=+1234567890
RECEIVER_NUMBER=+1234567890
EOF
```

## Usage

### As MCP Server

Run the MCP server directly:

```bash
server --user-id +YOUR_PHONE_NUMBER --transport stdio
```

### As Signal-Claude Bridge

The bridge provides a simple interface to interact with your workspace:

```bash
python3 signal_bridge.py --phone-number +YOUR_PHONE_NUMBER --workspace /home/ubuntu
```

### Available Commands in Bridge Mode

When you send messages to your Signal number:

- `/help` - Show command list
- `/status` - Show bridge status
- `/ls [path]` - List directory contents
- `/pwd` - Show current workspace path
- `/save <filename> <content>` - Save content to a file

## MCP Tools API

When used as an MCP server, these tools are available:

- **`send_message_to_user`** - Send a direct message to a Signal user
  ```python
  {"message": "Hello!", "user_id": "+1234567890"}
  ```

- **`send_message_to_group`** - Send a message to a Signal group
  ```python
  {"message": "Hello team!", "group_id": "My Group"}
  ```

- **`receive_message`** - Wait for and receive messages with timeout support
  ```python
  {"timeout": 30.0}  # Timeout in seconds
  ```

## Development

### Running Tests

```bash
pytest tests/
```

### Type Checking

```bash
mypy signal_mcp/
```

### Linting

```bash
ruff check .
```

### Formatting

```bash
ruff format .
```

## Systemd Service Management

Once installed as a service:

```bash
# Check status
sudo systemctl status signal-bridge

# View logs
sudo journalctl -u signal-bridge -f

# Stop service
sudo systemctl stop signal-bridge

# Start service
sudo systemctl start signal-bridge

# Restart service
sudo systemctl restart signal-bridge

# Disable auto-start
sudo systemctl disable signal-bridge
```

## Troubleshooting

### Signal registration fails
- Make sure you completed the CAPTCHA correctly
- Check that your phone number includes the country code (e.g., +1 for US)
- Try a different phone number if issues persist

### Bridge not receiving messages
- Check that signal-cli is properly registered: `signal-cli listAccounts`
- Test receiving manually: `signal-cli -u +YOUR_NUMBER receive --timeout 10`
- Check logs: `tail -f /tmp/signal-bridge.log`

### Service won't start
- Check service status: `sudo systemctl status signal-bridge`
- View logs: `sudo journalctl -u signal-bridge -n 50`
- Verify .env file exists and contains correct phone number

## Architecture

This project uses:
- [MCP](https://github.com/mcp-signal/mcp) for agent-API integration
- [signal-cli](https://github.com/AsamK/signal-cli) for Signal protocol
- Modern Python async patterns with asyncio
- Type annotations throughout
- FastMCP framework for easy MCP server creation

## Files Overview

- `signal_mcp/main.py` - Core MCP server implementation
- `signal_bridge.py` - Interactive bridge for phone chat
- `setup_signal.sh` - Automated Signal registration
- `run_bridge.sh` - Start bridge manually
- `install_service.sh` - Install as systemd service
- `check_mcp.py` - MCP client test script

## Security Notes

- Signal credentials stored in `~/.local/share/signal-cli/`
- Phone numbers stored in `.env` (git-ignored)
- Service runs as your user account
- File operations restricted to workspace directory

## License

This project integrates with Signal via signal-cli. Please review signal-cli's license and terms of service.

## Contributing

Contributions welcome! Please ensure:
- Tests pass: `pytest tests/`
- Type checking passes: `mypy signal_mcp/`
- Linting passes: `ruff check .`
- Code is formatted: `ruff format .`
