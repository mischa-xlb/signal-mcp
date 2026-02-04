# Quick Start Guide - Signal-Claude Bridge

## 🚀 Three Steps to Chat with Claude via Signal

### Step 1: Register Your Phone Number (5 minutes)

```bash
cd /home/ubuntu/git/llmidea/signal-mcp
./setup_signal.sh
```

**What you'll need:**
- Your phone number (with country code, e.g., +1234567890)
- Access to that phone to receive an SMS verification code
- A web browser to complete the CAPTCHA

**During setup:**
1. Enter your phone number when prompted
2. Open https://signalcaptchas.org/registration/generate.html
3. Complete the CAPTCHA
4. Copy the `signalcaptcha://...` URL
5. Paste it into the terminal
6. Wait for SMS with verification code
7. Enter the 6-digit code

### Step 2: Start the Bridge

**For testing (run in foreground):**
```bash
./run_bridge.sh
```

**For production (auto-start on boot):**
```bash
./install_service.sh
```

### Step 3: Send a Message!

1. Open Signal on your phone
2. Send a message to the number you just registered
3. Try: `/help`

## 📱 Commands You Can Use

Send these from your phone to the Signal number:

| Command | Description | Example |
|---------|-------------|---------|
| `/help` | Show command list | `/help` |
| `/status` | Check if bridge is running | `/status` |
| `/ls` | List files in workspace | `/ls` or `/ls git` |
| `/pwd` | Show workspace path | `/pwd` |
| `/save` | Save content to file | `/save test.txt Hello World` |

## 🔍 Checking if It's Working

### Method 1: Check the logs
```bash
tail -f /tmp/signal-bridge.log
```

### Method 2: If installed as service
```bash
sudo systemctl status signal-bridge
sudo journalctl -u signal-bridge -f
```

### Method 3: Test signal-cli directly
```bash
# Replace +1234567890 with your number
signal-cli -u +1234567890 receive --timeout 5
```

## 🛠️ Common Issues

### "No accounts found"
Run `./setup_signal.sh` first to register

### "Error receiving messages"
Check registration: `ls ~/.local/share/signal-cli/data/`
Should contain your phone number directory

### Bridge not responding
1. Check it's running: `ps aux | grep signal_bridge`
2. Check logs: `tail -f /tmp/signal-bridge.log`
3. Restart: `./run_bridge.sh`

### Service won't start
```bash
sudo systemctl status signal-bridge
sudo journalctl -u signal-bridge -n 50
```

## 💡 Pro Tips

1. **Keep it running:** Install as a service with `./install_service.sh`
2. **Check logs regularly:** `tail -f /tmp/signal-bridge.log`
3. **Test before deploying:** Use `./run_bridge.sh` first
4. **Your workspace:** By default it's `/home/ubuntu`, files saved with `/save` go here

## 🎯 Example Workflow

```bash
# 1. Register (one time only)
./setup_signal.sh

# 2. Start the bridge
./run_bridge.sh

# 3. From your phone, send to your Signal number:
#    "/ls git"
#    Response: Lists files in /home/ubuntu/git

# 4. Save something:
#    "/save notes.txt Remember to check logs"
#    Response: ✓ Saved to /home/ubuntu/notes.txt

# 5. Check status:
#    "/status"
#    Response: Shows bridge is active
```

## 📞 What Number Do I Message?

The **same number you registered** in Step 1. This is your server's Signal number.

When you registered with signal-cli, you linked that phone number to your code-server. Now you message that number from your personal phone, and the bridge running on your server responds.

## 🔐 Security Notes

- Your Signal credentials are stored in `~/.local/share/signal-cli/`
- Only you can message the server (your registered number)
- Files can only be saved in your workspace directory
- The bridge runs as your user account

## 🆘 Need Help?

1. Check README.md for detailed documentation
2. View troubleshooting section in README.md
3. Check logs: `tail -f /tmp/signal-bridge.log`
4. Test signal-cli: `signal-cli -u +YOUR_NUMBER receive --timeout 10`

## ⚡ Next Steps

Once working, you can:
- Integrate with Claude API for full AI responses
- Add custom commands to `signal_bridge.py`
- Set up notifications for long-running tasks
- Create shortcuts for common operations

Happy coding! 🎉
