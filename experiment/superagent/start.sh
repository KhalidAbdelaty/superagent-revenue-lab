#!/bin/bash
# Start dsh-superagent in tmux with the DeepSeek key in the process environment only.
set -a; . "$HOME/.secrets.env"; set +a
unset AGENT_GH_TOKEN
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
cd "$HOME/dsh-superagent" && scripts/dsh-superagent start; echo "start exit $?"
