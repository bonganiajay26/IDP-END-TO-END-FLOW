#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <ecr-repository-url>" >&2
  exit 1
fi

ECR_URL="$1"
FILE="gitops/apps/sample-api/overlays/dev/kustomization.yaml"

python - "$FILE" "$ECR_URL" <<'PY2'
from pathlib import Path
import sys
p=Path(sys.argv[1])
url=sys.argv[2]
text=p.read_text()
text=text.replace("REPLACE_ECR_REPOSITORY_URL", url)
p.write_text(text)
PY2

echo "Updated $FILE with $ECR_URL"
echo "Commit and push this change before bootstrapping Argo CD."
