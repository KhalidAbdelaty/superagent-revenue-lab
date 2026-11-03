# As run for runs 2 and 3 from Windows PowerShell; posts every GitHub step as the repository owner.
# steps.ps1 -Run 2 -Step negative|restore|incident|issue|comment|review|approve|merge [-Pr 2] [-Issue 1]
param([int]$Run, [string]$Step, [int]$Pr = 2, [int]$Issue = 1)
$ErrorActionPreference = 'Continue'
$proj = 'D:\2025\DataCamp\DeepSeek Superagent'
$repo = "KhalidAbdelaty/superagent-revenue-lab-run$Run"
$work = "D:\wsl\runs\run$Run\repo"
$gh = "$proj\companion\github"
Set-Location $work
function Stamp($what) { "{0} {1}" -f (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'), $what }
switch ($Step) {
  'negative' {
    $t = [IO.File]::ReadAllText("$work\README.md") -replace "(- Tests: \[tests/test_revenue.py\]\(tests/test_revenue.py\)\n)", "`$1- Data dictionary: [docs/data-dictionary.md](docs/data-dictionary.md)`n"
    [IO.File]::WriteAllText("$work\README.md", $t)
    git commit -q -am "docs: link the data dictionary from the README"; git push -q origin main 2>&1 | Out-Null
    Stamp "pushed negative $(git rev-parse --short HEAD)" }
  'restore' {
    git revert --no-edit HEAD | Out-Null; git push -q origin main 2>&1 | Out-Null
    Stamp "pushed restore $(git rev-parse --short HEAD)" }
  'incident' {
    Copy-Item -Force "$proj\companion\incident\data\events.csv" "$work\data\events.csv"
    Copy-Item -Force "$proj\companion\incident\tests\test_revenue.py" "$work\tests\test_revenue.py"
    git commit -q -am "Add 2026-10-30 events, including a webhook replay of evt_1009, and a replay regression test"; git push -q origin main 2>&1 | Out-Null
    Stamp "pushed incident $(git rev-parse --short HEAD)" }
  'issue' {
    $u = gh issue create -R $repo --title "revenue-integrity fails on main: 2026-10-30 overcounted" --body-file "$gh\issue.txt"
    Stamp "issue $u" }
  'comment' {
    $u = gh issue comment $Issue -R $repo --body-file "$gh\comment.txt"
    Stamp "comment $u" }
  'review' {
    gh pr review $Pr -R $repo --request-changes --body-file "$gh\review.txt"
    Stamp "review requested changes on PR $Pr" }
  'approve' {
    $head = gh pr view $Pr -R $repo --json headRefOid -q .headRefOid
    [IO.File]::WriteAllText("$env:TEMP\approve.txt", "Holdout suite and CI both pass on $($head.Substring(0,7)). Merging.")
    gh pr review $Pr -R $repo --approve --body-file "$env:TEMP\approve.txt"
    Stamp "approved PR $Pr at $($head.Substring(0,7))" }
  'merge' {
    gh pr merge $Pr -R $repo --merge
    Stamp "merged PR $Pr $(gh pr view $Pr -R $repo --json mergeCommit -q .mergeCommit.oid)" }
}
