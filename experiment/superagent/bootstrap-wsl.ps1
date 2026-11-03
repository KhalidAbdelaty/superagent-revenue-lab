# Creates the isolated dsh-superagent-lab distro and installs Superagent in it.
# Run: powershell -ExecutionPolicy Bypass -File companion\superagent\bootstrap-wsl.ps1
# It reads ..\..\.env next to companion\ (DEEPSEEK_API_KEY, AGENT_GH_TOKEN) and never prints it.
# Needs an Ubuntu 24.04 WSL rootfs at D:\wsl\ubuntu-noble.rootfs.tar.gz (from cloud-images.ubuntu.com/wsl).
param(
    [string]$Distro = 'dsh-superagent-lab',
    [string]$Dir = 'D:\wsl\dsh-lab',
    [string]$Repo = 'KhalidAbdelaty/superagent-revenue-lab',
    [switch]$NoStart    # build only; start later with: wsl -d <distro> -u superagent -- bash /home/superagent/start.sh
)
# Continue, not Stop: Windows PowerShell 5.1 turns a native program's stderr line (apt prints some) into a fatal error
$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$distro = $Distro
$src = Join-Path $PSScriptRoot '.'

function Send-File($path, $user, $target) {
    # Pipes a file into the distro without a BOM or CRLF line endings
    Get-Content -Raw $path | wsl -d $distro -u $user -- bash -c "umask 077; sed '1s/^\xEF\xBB\xBF//' | tr -d '\r' > $target"
}

wsl --import $distro $Dir D:\wsl\ubuntu-noble.rootfs.tar.gz --version 2
Send-File "$src\provision-root.sh" root /root/provision-root.sh
wsl -d $distro -u root -- bash -c 'bash /root/provision-root.sh > /root/provision.log 2>&1; tail -3 /root/provision.log'
wsl --terminate $distro    # restart so /etc/wsl.conf applies

# Secrets go straight into a 600 file; nothing is printed
Send-File (Join-Path $src '..\..\.env') superagent '~/.secrets.env'
wsl -d $distro -u superagent -- chmod 600 /home/superagent/.secrets.env
foreach ($f in 'setup-user.sh', 'start.sh', 'configure.sh', 'inspect.py', 'tickets.py', 'usage.py') {
    Send-File "$src\$f" superagent "~/$f"
}
wsl -d $distro -u superagent -- env "REPO=$Repo" bash /home/superagent/setup-user.sh
wsl -d $distro -u superagent -- tail -3 /home/superagent/setup-user.log

if ($NoStart) { return }
# Keep the distro alive in the background, then start the service (it opens its own tmux session)
Start-Process -WindowStyle Hidden wsl -ArgumentList '-d', $distro, '-u', 'superagent', '--', 'sleep', 'infinity'
wsl -d $distro -u superagent -- bash /home/superagent/start.sh
