#!/bin/bash
# start.sh - launches the MetaGhost API and the HUD together.
# Requires ./setup.sh to have been run first.
set -e
cd "$(dirname "$0")"

if [ ! -d "venv" ]; then
    echo "No venv found - run ./setup.sh first."
    exit 1
fi

if command -v tmux &> /dev/null; then
    SESSION="metaghost"
    tmux kill-session -t "$SESSION" 2>/dev/null || true

    tmux new-session -d -s "$SESSION" -n main
    tmux send-keys -t "$SESSION:main" "cd $(pwd)/server && ../venv/bin/python3 server.py" Enter

    tmux split-window -h -t "$SESSION:main"
    tmux send-keys -t "$SESSION:main" "cd $(pwd)/hud && npm start" Enter

    echo "Started API and HUD in tmux session '$SESSION'."
    echo "Attaching now - use Ctrl+B then D to detach without stopping anything."
    sleep 1
    tmux attach -t "$SESSION"
else
    echo "tmux not found - starting the API in the background instead."
    echo "Install tmux for a cleaner one-command launch: sudo apt install tmux"
    echo ""
    venv/bin/python3 server/server.py &
    API_PID=$!
    trap "kill $API_PID 2>/dev/null" EXIT
    sleep 1
    cd hud && npm start
fi
