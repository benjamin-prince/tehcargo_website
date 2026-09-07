#!/usr/bin/env bash
# Deploy the TehCargo public site: build locally → Docker Hub → pull on the VPS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SSH_KEY="$HOME/LightsailDefaultKey-eu-west-3.pem"
VPS="ubuntu@tehtek.com"
REMOTE_DIR="/opt/tehcargo-web"
IMAGE="boulaz2002/tehcargo-web:latest"

echo "==> Building image..."
docker build -t "$IMAGE" .

echo "==> Pushing to Docker Hub..."
docker push "$IMAGE"

echo "==> Deploying on VPS..."
ssh -i "$SSH_KEY" "$VPS" "
  mkdir -p $REMOTE_DIR
  cd $REMOTE_DIR
  docker compose pull tehcargo-web 2>/dev/null || true
  docker compose up -d tehcargo-web
  sleep 2
  docker ps --filter name=tehcargo_web --format '{{.Names}}  {{.Status}}'
"

echo "==> Health check..."
sleep 3
code=\$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://teh-cargo.com/ || true)
echo "    https://teh-cargo.com -> HTTP \$code"

echo "==> Done."
