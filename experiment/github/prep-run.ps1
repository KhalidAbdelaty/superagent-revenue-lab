# As run for runs 2 and 3 from Windows PowerShell. Expects the companion folder at $proj and .env beside it.
# prep.ps1 -Run 2 : create a fresh public experiment repo with the green baseline, ruleset, and agent collaborator
param([int]$Run)
$ErrorActionPreference = 'Stop'
$proj = 'D:\2025\DataCamp\DeepSeek Superagent'
$name = "superagent-revenue-lab-run$Run"
$repo = "KhalidAbdelaty/$name"
$work = "D:\wsl\runs\run$Run\repo"
New-Item -ItemType Directory -Force $work | Out-Null
Copy-Item -Recurse -Force "$proj\companion\revenue-lab\*" $work
Copy-Item -Force "$proj\companion\revenue-lab\.gitignore" $work
New-Item -ItemType Directory -Force "$work\.github\workflows" | Out-Null
Copy-Item -Force "$proj\companion\revenue-lab\.github\workflows\ci.yml" "$work\.github\workflows\ci.yml"
Set-Location $work
git init -q -b main
git add -A
git -c core.autocrlf=false commit -q -m "Baseline revenue pipeline, tests, and CI"
gh repo create $repo --public --description "Run $Run of the DeepSeek Superagent observe-first CI experiment" --source . --push | Out-Null
gh api "repos/$repo/rulesets" --method POST --input "$proj\companion\github\ruleset.json" --jq .id
gh api "repos/$repo/collaborators/tester-31op" --method PUT -f permission=push --jq .id
# Agent side: accept the invitation and mark old notifications read, without printing the token
$tok = ((Get-Content "$proj\.env") | Where-Object { $_ -match '^AGENT_GH_TOKEN=' }) -replace '^AGENT_GH_TOKEN=', '' -replace '"', ''
$h = @{ Authorization = "token $tok"; Accept = 'application/vnd.github+json' }
Start-Sleep 3
$inv = Invoke-RestMethod -Headers $h https://api.github.com/user/repository_invitations | Where-Object { $_.repository.full_name -eq $repo }
foreach ($i in $inv) { Invoke-RestMethod -Method Patch -Headers $h "https://api.github.com/user/repository_invitations/$($i.id)" | Out-Null; "accepted $($i.id)" }
Invoke-RestMethod -Method Put -Headers $h -Body '{"read":true}' https://api.github.com/notifications | Out-Null
"notifications marked read"
git log --oneline -1
