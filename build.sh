#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "[*] Writing Python 3.13 workflow..."

mkdir -p .github/workflows

cat > .github/workflows/build.yml << 'EOF'
name: build-pydantic-android

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python 3.13
        uses: actions/setup-python@v5
        with:
          python-version: "3.13"

      - name: Install Rust + target
        run: |
          rustup target add aarch64-linux-android

      - name: Install build deps
        run: |
          pip install maturin
          sudo apt-get update
          sudo apt-get install -y gcc-aarch64-linux-gnu

      - name: Download source
        run: |
          pip download pydantic-core --no-binary=:all:
          ls

      - name: Build wheel
        run: |
          export PYO3_CROSS=1
          export PYO3_CROSS_PYTHON_VERSION=3.13
          tar -xf pydantic_core-*.tar.gz
          DIR=$(ls -d pydantic_core-* | head -n 1)
          cd "$DIR"
          maturin build --release --target aarch64-linux-android --skip-auditwheel

      - name: Upload wheel
        uses: actions/upload-artifact@v4
        with:
          name: wheel
          path: pydantic_core-*/target/wheels/*.whl
EOF

echo "[*] Committing workflow..."
git add .
git commit -m "python 3.13 build fix" || echo "[*] No changes"
git push

echo "[*] Triggering workflow..."
gh workflow run build.yml

sleep 5

RUN_ID=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')

echo "[*] Watching build..."
gh run watch $RUN_ID

echo "[*] Done"
