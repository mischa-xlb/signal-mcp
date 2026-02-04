#!/usr/bin/env python3
"""
Signal-Claude Bridge for Code-Server
Allows you to interact with Claude via Signal messages on your phone.
"""
import asyncio
import sys
import signal as sig_module
import argparse
import logging
from pathlib import Path
from datetime import datetime

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/tmp/signal-bridge.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger("signal-bridge")

# Add the project to the path
sys.path.insert(0, str(Path(__file__).parent))

from signal_mcp.main import (  # noqa: E402
    MessageResponse,
    _parse_receive_output,
    _run_signal_cli,
    _send_message,
    config,
)


class SignalBridge:
    """Bridge between Signal messages and Claude Code workspace."""

    def __init__(self, phone_number: str, workspace_path: str = "/home/ubuntu"):
        self.phone_number = phone_number
        self.workspace_path = Path(workspace_path)
        self.running = False
        self.command_handlers = {
            "/help": self.handle_help,
            "/status": self.handle_status,
            "/ls": self.handle_ls,
            "/pwd": self.handle_pwd,
            "/save": self.handle_save,
        }
        # Set the global config for signal_mcp.main to use
        config.user_id = phone_number
        logger.info(f"Initialized Signal Bridge for {phone_number}")
        logger.info(f"Workspace: {workspace_path}")

    async def handle_help(self, sender: str, args: list) -> str:
        """Show available commands."""
        return """Available commands:
/help - Show this help
/status - Show bridge status
/ls [path] - List files in directory
/pwd - Show current workspace
/save <filename> <content> - Save content to file

You can also send any message to Claude and get a response!"""

    async def handle_status(self, sender: str, args: list) -> str:
        """Show bridge status."""
        uptime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        return f"""Signal-Claude Bridge Status:
✓ Active
✓ Phone: {self.phone_number}
✓ Workspace: {self.workspace_path}
✓ Time: {uptime}"""

    async def handle_ls(self, sender: str, args: list) -> str:
        """List files in directory."""
        try:
            target_path = self.workspace_path / args[0] if args else self.workspace_path
            if not target_path.exists():
                return f"Error: Path does not exist: {target_path}"

            if target_path.is_file():
                return f"File: {target_path.name}"

            files = list(target_path.iterdir())
            if not files:
                return f"Empty directory: {target_path}"

            result = f"Contents of {target_path}:\n"
            for item in sorted(files)[:20]:  # Limit to 20 items
                prefix = "📁" if item.is_dir() else "📄"
                result += f"{prefix} {item.name}\n"

            if len(files) > 20:
                result += f"... and {len(files) - 20} more items"

            return result
        except Exception as e:
            logger.error(f"Error in handle_ls: {e}")
            return f"Error: {str(e)}"

    async def handle_pwd(self, sender: str, args: list) -> str:
        """Show current workspace."""
        return f"Workspace: {self.workspace_path}"

    async def handle_save(self, sender: str, args: list) -> str:
        """Save content to a file."""
        if len(args) < 2:
            return "Usage: /save <filename> <content>"

        try:
            filename = args[0]
            content = " ".join(args[1:])

            # Security: prevent path traversal
            if ".." in filename or filename.startswith("/"):
                return "Error: Invalid filename"

            file_path = self.workspace_path / filename
            file_path.write_text(content)

            return f"✓ Saved to {file_path}"
        except Exception as e:
            logger.error(f"Error in handle_save: {e}")
            return f"Error: {str(e)}"

    async def process_message(self, message: MessageResponse) -> str:
        """Process an incoming message and generate a response."""
        if not message.message or not message.sender_id:
            return None

        text = message.message.strip()
        sender = message.sender_id

        logger.info(f"Processing message from {sender}: {text[:50]}...")

        # Handle commands
        if text.startswith("/"):
            parts = text.split()
            command = parts[0].lower()
            args = parts[1:] if len(parts) > 1 else []

            handler = self.command_handlers.get(command)
            if handler:
                return await handler(sender, args)
            else:
                return f"Unknown command: {command}\nType /help for available commands"

        # For non-command messages, provide a simple echo response
        # In a full implementation, this would integrate with Claude API
        return f"Received: {text}\n\nNote: Full Claude integration requires additional setup. Use commands like /help, /status, /ls, /save for now."

    async def send_response(self, recipient: str, message: str):
        """Send a response back via Signal."""
        try:
            success = await _send_message(message, recipient, is_group=False)
            if success:
                logger.info(f"Sent response to {recipient}: {message[:50]}...")
            else:
                logger.error(f"Failed to send response to {recipient}")
        except Exception as e:
            logger.error(f"Error sending response: {e}")

    async def run(self):
        """Main loop: receive messages and respond."""
        self.running = True
        logger.info("Signal Bridge started. Waiting for messages...")
        logger.info("Send a message to your Signal number to test!")

        consecutive_errors = 0
        max_consecutive_errors = 5

        while self.running:
            try:
                # Receive messages with 5 second timeout for faster response
                # Trade-off: More frequent polling = faster response but more CPU
                cmd = f"signal-cli -u {self.phone_number} receive --timeout 5"
                stdout, stderr, return_code = await _run_signal_cli(cmd)

                if return_code != 0:
                    if "timeout" not in stderr.lower():
                        logger.warning(f"Receive error: {stderr}")
                    continue

                if not stdout.strip():
                    continue

                # Parse the message
                message = await _parse_receive_output(stdout)

                if message and message.message:
                    logger.info(
                        f"Received message from {message.sender_id}: {message.message[:50]}..."
                    )

                    # Process and respond
                    response = await self.process_message(message)
                    if response:
                        await self.send_response(message.sender_id, response)

                    consecutive_errors = 0

            except KeyboardInterrupt:
                logger.info("Received shutdown signal")
                break
            except Exception as e:
                consecutive_errors += 1
                logger.error(f"Error in main loop: {e}", exc_info=True)

                if consecutive_errors >= max_consecutive_errors:
                    logger.error(
                        f"Too many consecutive errors ({consecutive_errors}). Shutting down."
                    )
                    break

                await asyncio.sleep(5)

        logger.info("Signal Bridge stopped")

    def stop(self):
        """Stop the bridge."""
        self.running = False


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Signal-Claude Bridge for Code-Server")
    parser.add_argument(
        "--phone-number",
        "-p",
        required=True,
        help="Your Signal phone number (with country code)",
    )
    parser.add_argument(
        "--workspace",
        "-w",
        default="/home/ubuntu",
        help="Workspace directory path (default: /home/ubuntu)",
    )

    args = parser.parse_args()

    # Validate phone number
    if not args.phone_number.startswith("+"):
        logger.error("Phone number must start with + and include country code")
        sys.exit(1)

    # Create and run bridge
    bridge = SignalBridge(args.phone_number, args.workspace)

    # Handle signals
    def signal_handler(signum, frame):
        logger.info(f"Received signal {signum}")
        bridge.stop()

    sig_module.signal(sig_module.SIGINT, signal_handler)
    sig_module.signal(sig_module.SIGTERM, signal_handler)

    try:
        await bridge.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
