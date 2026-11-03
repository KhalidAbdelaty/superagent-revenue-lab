#!/bin/bash
# Saves settings through the Management API (docs/006-deployment.md). Run as superagent while the service runs.
set -e
REPO="${REPO:-KhalidAbdelaty/superagent-revenue-lab}"   # owner/name of the experiment repository
api=http://127.0.0.1:3082/orchestrator/api
H=(-H 'x-orchestrator-request: 1' -H 'content-type: application/json')
rev() { curl -s "${H[@]}" $api/settings | jq "$1"; }
put() { curl -s -X PUT "${H[@]}" "$api/settings/$1" -d "$2"; echo; }
wait_up() { for i in $(seq 1 60); do curl -s -o /dev/null "${H[@]}" $api/state && return; sleep 2; done; }
STEP=${1:-all}

if [ "$STEP" = source ] || [ "$STEP" = all ]; then
  r=$(rev '.sources[] | select(.id == "github") | .revision')
  put source:github "{\"value\": {\"enabled\": true, \"config\": {\"repository\": \"$REPO\", \"cli\": \"$HOME/.local/bin/gh-agent\", \"observeCi\": ${OBSERVE_CI:-false}}}, \"revision\": $r}"
  sleep 3; wait_up
fi

if [ "$STEP" = policy ] || [ "$STEP" = all ]; then
  r=$(rev '.blocks.policy.revision')
  read -r -d '' RULE <<'R' || true
A default-branch CI result in which the check named revenue-integrity newly fails. That check runs the pytest suite guarding the daily revenue totals produced by revenue/pipeline.py. Judge only from the check names and results you can read for that commit; do not guess a root cause. Failures limited to other checks, such as docs-check (README links), do not match. A recovery where every check passes does not match. Work, if accepted: investigate the failing revenue-integrity tests, fix the pipeline without weakening or deleting any assertion, add a regression test, and open a pull request for human review. Never merge.
R
  jq -n --arg ins "$RULE" --argjson r "$r" '{value: {
      rules: [{id: "revenue-integrity", name: "Revenue integrity CI failures", enabled: true, instruction: $ins}],
      sources: {github: {allowed: [{id: "KhalidAbdelaty"}], bots: [], admission: {ci: {unlistedUnaddressed: "inferred"}}}}},
    revision: $r}' > /tmp/policy.json
  curl -s -X PUT "${H[@]}" "$api/settings/policy" -d @/tmp/policy.json; echo
fi

if [ "$STEP" = eval ] || [ "$STEP" = all ]; then
  r=$(rev '.blocks.eval.revision')
  v=$(rev '.blocks.eval.value | .mode = "observe"')
  put eval "{\"value\": $v, \"revision\": $r}"
fi

if [ "$STEP" = executor ] || [ "$STEP" = all ]; then
  r=$(rev '.blocks.executor.revision')
  CLONE="$HOME/src/${REPO#*/}"
  PREP="git -C $CLONE fetch --no-tags \"https://github.com/\$DSH_SUPERAGENT_GITHUB_REPOSITORY.git\" \"\${DSH_SUPERAGENT_GITHUB_PR_HEAD:-HEAD}:refs/dsh-superagent/\$DSH_SUPERAGENT_TICKET\" && git -C $CLONE worktree add -b \"agent/\$DSH_SUPERAGENT_NAME\" \"\$DSH_SUPERAGENT_DIR\" \"refs/dsh-superagent/\$DSH_SUPERAGENT_TICKET\""
  v=$(rev '.blocks.executor.value' | jq --arg p "$PREP" '.prepare = $p')
  put executor "{\"value\": $v, \"revision\": $r}"
fi

if [ "$STEP" = show ] || [ "$STEP" = all ]; then
  curl -s "${H[@]}" $api/settings | jq '{policyVersion, policy: .blocks.policy.value, eval: .blocks.eval.value, executor: .blocks.executor.value | {model, maxWorkers, directory, prepare, blockedCommands}, github: (.sources[] | select(.id=="github") | {value, problem})}'
fi
