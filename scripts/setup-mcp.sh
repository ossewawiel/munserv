#!/bin/bash
# MCP Server Setup Script for Claude Code in WSL2
# Run from project root: ./scripts/setup-mcp.sh

set -e

echo "=== MCP Server Setup for Claude Code ==="
echo ""

# Check Node.js (needed for npx)
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Install it first:"
    echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
    echo "   source ~/.bashrc"
    echo "   nvm install 20"
    exit 1
fi

echo "✅ Node.js $(node --version) found"

# Check Claude Code
if ! command -v claude &> /dev/null; then
    echo "❌ Claude Code not found. Install it first:"
    echo "   npm install -g @anthropic-ai/claude-code"
    exit 1
fi

echo "✅ Claude Code found"
echo ""

# Add MCP servers using claude mcp add
# Note: npx will download packages on-demand, no global install needed

echo "📦 Adding MCP servers to Claude Code..."
echo ""

# Memory server - persists decisions across sessions
echo "  → Adding memory server..."
claude mcp add --transport stdio memory --scope local -- npx -y @modelcontextprotocol/server-memory \
    && echo "    ✅ memory added" \
    || echo "    ⚠️  memory: may already exist or failed"

# Fetch server - HTTP requests for testing endpoints
echo "  → Adding fetch server..."
claude mcp add --transport stdio fetch --scope local -- npx -y @modelcontextprotocol/server-fetch \
    && echo "    ✅ fetch added" \
    || echo "    ⚠️  fetch: may already exist or failed"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "📋 Verify with:"
echo "   claude mcp list"
echo ""
echo "📋 Optional servers (add when needed):"
echo ""
echo "1. GitHub MCP (requires Personal Access Token):"
echo "   export GITHUB_TOKEN='ghp_your_token_here'"
echo "   claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header \"Authorization: Bearer \$GITHUB_TOKEN\""
echo ""
echo "2. PostgreSQL MCP (requires database running):"
echo "   # Start database first:"
echo "   cd infrastructure/docker && docker-compose up -d"
echo "   # Then add MCP:"
echo "   claude mcp add --transport stdio postgres -- npx -y @modelcontextprotocol/server-postgres \"postgresql://munserv:munserv_dev@localhost:5435/munserv_dev\""
echo ""
echo "3. Sequential Thinking MCP (for complex reasoning):"
echo "   claude mcp add --transport stdio thinking -- npx -y @modelcontextprotocol/server-sequential-thinking"
echo ""
echo "📋 Manage servers:"
echo "   claude mcp list          # List all servers"
echo "   claude mcp get <name>    # Get server details"
echo "   claude mcp remove <name> # Remove a server"
echo "   /mcp                     # Check status inside Claude Code"
echo ""
