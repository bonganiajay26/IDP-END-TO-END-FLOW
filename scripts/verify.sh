#!/usr/bin/env bash
set -euo pipefail

python -m compileall -q sample-service
(
  cd sample-service
  python -m pytest -q
)

terraform -chdir=infra/terraform fmt -check -recursive

echo "Static project checks passed."
