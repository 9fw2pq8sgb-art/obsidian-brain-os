#!/usr/bin/env python3
# Ensure qmd's 'brain' collection (with ignore patterns) exists in ~/.config/qmd/index.yml,
# MERGING into any existing config (preserves other collections + models). Idempotent.
# Usage: qmd-config.py <vault-path>
import os, sys, subprocess

VAULT = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("BRAIN_VAULT", "")
if not VAULT or not os.path.isdir(VAULT):
    print("qmd-config: vault path missing/invalid", file=sys.stderr); sys.exit(1)

CFG = os.path.expanduser("~/.config/qmd/index.yml")
IGNORE = ["**/session-*.md", "04 Archive/Sessions/**", "**/graphify-out/**"]
MODELS = {
    "embed":    "hf:ggml-org/embeddinggemma-300M-GGUF/embeddinggemma-300M-Q8_0.gguf",
    "generate": "hf:tobil/qmd-query-expansion-1.7B-gguf/qmd-query-expansion-1.7B-q4_k_m.gguf",
    "rerank":   "hf:ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF/qwen3-reranker-0.6b-q8_0.gguf",
}

def get_yaml():
    try:
        import yaml; return yaml
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "--user", "--quiet", "pyyaml"], check=False)
        import yaml; return yaml

try:
    yaml = get_yaml()
except Exception:
    print("qmd-config: pyyaml unavailable. Fallback: run `qmd collection add \"%s\" --name brain` "
          "and add ignore patterns %s manually." % (VAULT, IGNORE), file=sys.stderr)
    sys.exit(2)

data = {}
if os.path.exists(CFG):
    with open(CFG) as f:
        data = yaml.safe_load(f) or {}
if not isinstance(data, dict):
    data = {}

cols = data.setdefault("collections", {})
brain = cols.get("brain") or {}          # keep existing context/keys if present
brain["path"] = VAULT
brain.setdefault("pattern", "**/*.md")
brain["ignore"] = IGNORE
cols["brain"] = brain
data.setdefault("models", MODELS)        # only set models if none configured yet

os.makedirs(os.path.dirname(CFG), exist_ok=True)
with open(CFG, "w") as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)
print("qmd-config: ensured 'brain' collection + ignore in %s (preserved %d other collection(s))"
      % (CFG, max(0, len(cols) - 1)))
