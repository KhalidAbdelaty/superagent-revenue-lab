#!/bin/bash
# Root provisioning inside the freshly imported dsh-superagent-lab WSL distro.
# Rebuilt from this distro's apt history and /usr/local/bin after the recorded run.
set -e
apt-get update -q
apt-get install -y -q git tmux python3 python3-venv python3-pip curl ca-certificates jq xz-utils procps zstd

# Node.js 22.20.0 and GitHub CLI 2.83.1, the versions the run used
curl -fsSL https://nodejs.org/dist/v22.20.0/node-v22.20.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1
curl -fsSL https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_linux_amd64.tar.gz | tar -xz -C /tmp
install -m 755 /tmp/gh_2.83.1_linux_amd64/bin/gh /usr/local/bin/gh

# Dedicated OS user whose home nobody else can read
id superagent >/dev/null 2>&1 || useradd -m -s /bin/bash superagent
chmod 700 /home/superagent

# No Windows drives, no Windows programs, no Windows PATH
cat > /etc/wsl.conf <<'W'
[automount]
enabled = false
mountFsTab = false
[interop]
enabled = false
appendWindowsPath = false
[user]
default = superagent
W
node -v; gh --version | head -1; echo ROOT_SETUP_DONE
