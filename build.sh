#!/data/data/com.termux/files/usr/bin/bash

set -e

REPO="pydantic-android"

echo "[*] Creating repo..."
gh repo create $REPO --public --clone || true
cd $REPO

echo "[*] Creating workflow..."
mkdir -p .github/workflows

cat > .github/workflows/build.yml << 'EOF'
name: Build pydantic-core (Android)

on: [workflow_dispatch]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: rustup target add aarch64-linux-android

      - run: |
          pip install maturin
          sudo apt-get update
          sudo apt-get install -y gcc-aarch64-linux-gnu

      - run: pip download pydantic-core --no-binary=:all:

      - run: |
          cd pydantic-core*
          maturin build --release --target aarch64-linux-android

      - uses: actions/upload-artifact@v4
        with:
          name: wheel
          path: pydantic-core*/target/wheels/*.whl
EOF

echo "[*] Pushing workflow..."
git add .
git commit -m "Add build workflow" || true
git push

echo "[*] Triggering workflow..."
gh workflow run "Build pydantic-core (Android)"

sleep 5

echo "[*] Getting latest run ID..."
RUN_ID=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')

echo "[*] Watching build..."
gh run watch $RUN_ID

echo "[*] Downloading artifact..."
gh run download $RUN_ID

echo "[*] Installing wheel..."
WHEEL=$(find . -name "*.whl" | head -n 1)

pip install "$WHEEL"
pip install pydantic

echo "[✓] Done!"
python -c "import pydantic; print(pydantic.__version__)"
