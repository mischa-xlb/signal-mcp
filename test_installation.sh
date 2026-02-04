#!/bin/bash
# Test script to verify Signal-Claude Bridge installation

echo "========================================"
echo "Signal-Claude Bridge Installation Test"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

cd "$(dirname "$0")"

# Check signal-cli
echo "Checking signal-cli..."
if command -v signal-cli &> /dev/null; then
    VERSION=$(signal-cli --version 2>&1)
    check_pass "signal-cli installed: $VERSION"
else
    check_fail "signal-cli not found"
    exit 1
fi

# Check Python
echo ""
echo "Checking Python..."
if [ -f venv/bin/python3.13 ]; then
    VERSION=$(venv/bin/python3.13 --version)
    check_pass "Python installed: $VERSION"
else
    check_fail "Python 3.13 not found in venv"
    exit 1
fi

# Check virtual environment
echo ""
echo "Checking virtual environment..."
if [ -d venv ]; then
    check_pass "Virtual environment exists"
else
    check_fail "Virtual environment not found"
    exit 1
fi

# Check installed packages
echo ""
echo "Checking Python packages..."
PACKAGES=("mcp" "pytest" "mypy" "ruff")
for pkg in "${PACKAGES[@]}"; do
    if venv/bin/python3.13 -m pip show "$pkg" &> /dev/null; then
        VERSION=$(venv/bin/python3.13 -m pip show "$pkg" | grep Version: | cut -d' ' -f2)
        check_pass "$pkg $VERSION installed"
    else
        check_fail "$pkg not installed"
    fi
done

# Check signal-mcp package
echo ""
echo "Checking signal-mcp package..."
if venv/bin/python3.13 -c "import signal_mcp.main" 2>/dev/null; then
    check_pass "signal-mcp package imports successfully"
else
    check_fail "signal-mcp package import failed"
fi

# Check scripts
echo ""
echo "Checking scripts..."
SCRIPTS=("setup_signal.sh" "run_bridge.sh" "install_service.sh" "signal_bridge.py")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        check_pass "$script exists and is executable"
    else
        check_fail "$script missing or not executable"
    fi
done

# Check Signal registration
echo ""
echo "Checking Signal registration..."
if [ -f ~/.local/share/signal-cli/data/accounts.json ]; then
    ACCOUNTS=$(cat ~/.local/share/signal-cli/data/accounts.json | grep -o '"accounts" : \[ [^]]*' | grep -o '\+[0-9]*')
    if [ -z "$ACCOUNTS" ]; then
        check_warn "No Signal accounts registered yet"
        echo "   Run ./setup_signal.sh to register"
    else
        check_pass "Signal account registered: $ACCOUNTS"
    fi
else
    check_warn "Signal CLI data directory not found"
fi

# Check .env file
echo ""
echo "Checking configuration..."
if [ -f .env ]; then
    check_pass ".env file exists"
    if grep -q "SENDER_NUMBER=" .env; then
        SENDER=$(grep "SENDER_NUMBER=" .env | cut -d'=' -f2)
        check_pass "SENDER_NUMBER configured: $SENDER"
    else
        check_warn "SENDER_NUMBER not set in .env"
    fi
else
    check_warn ".env file not found"
    echo "   Run ./setup_signal.sh to create it"
fi

# Run tests
echo ""
echo "Running tests..."
if venv/bin/python3.13 -m pytest tests/ -q &> /dev/null; then
    check_pass "All tests passing"
else
    check_fail "Some tests failing"
    echo "   Run: pytest tests/ -v"
fi

# Check type checking
echo ""
echo "Running type check..."
if venv/bin/mypy signal_mcp/ &> /dev/null; then
    check_pass "Type checking passed"
else
    check_warn "Type checking issues found"
    echo "   Run: mypy signal_mcp/"
fi

# Check linting
echo ""
echo "Running linter..."
if venv/bin/ruff check . &> /dev/null; then
    check_pass "Linting passed"
else
    check_warn "Linting issues found"
    echo "   Run: ruff check ."
fi

# Summary
echo ""
echo "========================================"
echo "Installation Summary"
echo "========================================"
echo ""

if [ -f .env ] && [ -n "$ACCOUNTS" ]; then
    echo -e "${GREEN}✓ Ready to use!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./run_bridge.sh"
    echo "  2. Send a message from your phone"
    echo "  3. Try: /help"
    echo ""
    echo "Or install as service:"
    echo "  ./install_service.sh"
else
    echo -e "${YELLOW}⚠ Setup incomplete${NC}"
    echo ""
    echo "To complete setup:"
    echo "  1. Run: ./setup_signal.sh"
    echo "  2. Follow the prompts to register"
    echo "  3. Run: ./run_bridge.sh"
fi

echo ""
