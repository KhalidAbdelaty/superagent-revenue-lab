#!/bin/bash
# Runs as the dedicated `superagent` OS user inside the dsh-superagent-lab WSL distro.
set -e  # no -x: tracing would copy secrets into the log
REPO="${REPO:-KhalidAbdelaty/superagent-revenue-lab}"   # owner/name of the experiment repository
exec > "$HOME/setup-user.log" 2>&1
set -a; . "$HOME/.secrets.env"; set +a
export NPM_CONFIG_PREFIX="$HOME/.npm-global" PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
grep -q npm-global "$HOME/.profile" || echo 'export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"' >> "$HOME/.profile"
mkdir -p "$HOME/.local/bin" "$HOME/src"

# 1. DeepSeek Harness at the version docs/006-deployment.md pins, and pnpm at the version package.json pins
npm install -g @deepseek-ai/dsh@0.2.1-rc.3 pnpm@11.7.0

# 2. The prototype, pinned to the only upstream commit
git clone https://github.com/deepseek-ai/dsh-superagent-prototype.git "$HOME/dsh-superagent"
cd "$HOME/dsh-superagent" && git checkout --detach 6337fc823ce20251c8de8085948165c81aaa701e
pnpm install && pnpm build

# 3. Agent GitHub CLI that only sees the agent account (docs/006-deployment.md, Accounts)
cat > "$HOME/.local/bin/gh-agent" <<'W'
#!/bin/sh
GH_CONFIG_DIR="$HOME/.config/gh-agent" exec gh "$@"
W
chmod +x "$HOME/.local/bin/gh-agent"
printf '%s' "$AGENT_GH_TOKEN" | env -u GH_TOKEN -u GITHUB_TOKEN gh-agent auth login --hostname github.com --with-token
gh-agent api user --jq .login

# 4. Local clone the prepare command adds worktrees from (no credentials stored in .git/config)
git -c credential.helper= -c 'credential.helper=!gh-agent auth git-credential' \
  clone "https://github.com/$REPO.git" "$HOME/src/${REPO#*/}"

# 5. Dedicated profile from the Web template, then the bundle
cd "$HOME/dsh-superagent"
dsh superagent --from-default-profile web --dump-config > /dev/null
dsh plugin --profile superagent add "link:$PWD"
cat > "$HOME/.dsh/profiles/superagent/cordis.patch.yml" <<Y
- id: webserver
  config:
    host: 127.0.0.1
    port: 3082
- id: dsh-superagent
  config:
    stateDir: $HOME/.dsh/state/superagent
Y
node -v; pnpm -v; git --version; tmux -V; python3 --version; gh --version | head -1; dsh --version
git -C "$HOME/dsh-superagent" rev-parse HEAD
echo USER_SETUP_DONE
