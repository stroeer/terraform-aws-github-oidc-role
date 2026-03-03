#!/usr/bin/env bash
#
# Pre-commit hook: runs wizcli scan on directories containing changed Terraform files.
# Skips automatically on GitHub Actions (Wiz IaC agent is injected for PR builds).
#
# Configuration (environment variables):
#   WIZCLI_POLICY  — Wiz CICD scan policy name (default: "Buzz IaC Policy").
set -euo pipefail

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  echo "[wizcli] running on GitHub Actions — skipping (Wiz IaC agent handles scanning)"
  exit 0
fi

WIZCLI_POLICY="${WIZCLI_POLICY:-Buzz IaC Policy}"

if ! command -v wizcli &>/dev/null; then
  echo "[wizcli] not installed — skipping scan"
  exit 0
fi

# pre-commit passes changed filenames as arguments — resolve to unique directories
stacks=()
for file in "$@"; do
  stacks+=("$(dirname "$file")")
done

if [[ ${#stacks[@]} -eq 0 ]]; then
  exit 0
fi

# deduplicate
IFS=$'\n' read -r -d '' -a stacks < <(printf '%s\n' "${stacks[@]}" | sort -u && printf '\0') || true

failed=0
for stack in "${stacks[@]}"; do
  echo "[wizcli] scanning $stack"
  if ! wizcli scan dir "$stack" --use-device-code --name "terraform-aws-github-oidc-role/$stack" -p "$WIZCLI_POLICY" --disabled-scanners=AIModels,Malware --by-policy-hits=BLOCK --no-publish --ignore-comments; then
    failed=1
  fi
done

exit $failed
