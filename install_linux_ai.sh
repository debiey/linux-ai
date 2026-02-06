#!/usr/bin/env bash
set -e

echo "=== Linux-AI Installer ==="

BASE_DIR="$HOME/linux_ai"
BIN_DIR="$BASE_DIR/bin"
CORE_DIR="$BASE_DIR/core"
DATA_DIR="$BASE_DIR/data"

# 1. Create directories
echo "[+] Creating directory structure..."
mkdir -p "$BIN_DIR" "$CORE_DIR" "$DATA_DIR"

# 2. Create memory file if not exists
MEMORY_FILE="$DATA_DIR/memory.json"
if [ ! -f "$MEMORY_FILE" ]; then
  echo "[+] Initializing memory..."
  cat > "$MEMORY_FILE" <<EOF
{
  "history": [],
  "patterns": {},
  "meta": {}
}
EOF
fi

# 3. Install intent engine
echo "[+] Installing intent engine..."
cat > "$CORE_DIR/intent.py" <<'PYCODE'
#!/usr/bin/env python3
"""
Linux-AI Intent Analysis Engine
Safety-first learning with decay & negative constraints
"""

import sys
import json
import shutil
import time
from pathlib import Path
from difflib import SequenceMatcher
from math import exp

MEMORY_FILE = Path.home() / "linux_ai" / "data" / "memory.json"

DECAY_HALF_LIFE = 7 * 24 * 3600
MIN_CONFIDENCE = 0.4
PRUNE_INTERVAL = 24 * 3600

COMMON_COMMANDS = {
    "ls", "cd", "rm", "cp", "mv", "cat", "nano", "vim",
    "sudo", "systemctl", "mkdir", "rmdir", "touch", "pwd"
}

DANGEROUS_PATTERNS = [
    "rm -rf /",
    "mkfs",
    "dd if=",
    ":(){:|:&};:"
]

CRITICAL_PATHS = ["/", "/boot", "/etc", "/usr", "/bin", "/sbin"]

def similarity(a, b):
    return SequenceMatcher(None, a, b).ratio()

def normalize(cmd):
    parts = cmd.split()
    return " ".join(parts[:2]) if len(parts) >= 2 else cmd

def load_memory():
    if MEMORY_FILE.exists():
        return json.loads(MEMORY_FILE.read_text())
    return {"history": [], "patterns": {}, "meta": {}}

def save_memory(memory):
    MEMORY_FILE.write_text(json.dumps(memory, indent=2))

def compute_confidence(count, last_seen):
    age = time.time() - last_seen
    decay = exp(-age / DECAY_HALF_LIFE)
    base = min(0.6 + count * 0.15, 0.95)
    return round(base * decay, 2)

def prune_patterns(memory):
    now = time.time()
    last_prune = memory.get("meta", {}).get("last_prune", 0)

    if now - last_prune < PRUNE_INTERVAL:
        return

    to_delete = []
    for k, v in memory["patterns"].items():
        conf = compute_confidence(v["count"], v["last_seen"])
        if conf < MIN_CONFIDENCE:
            to_delete.append(k)

    for k in to_delete:
        del memory["patterns"][k]

    memory.setdefault("meta", {})["last_prune"] = int(now)

def is_dangerous_command(cmd):
    return any(p in cmd for p in DANGEROUS_PATTERNS)

def escalates_privilege(wrong, correct):
    return not wrong.startswith("sudo") and correct.startswith("sudo")

def touches_critical_path(cmd):
    return any(f" {p}" in cmd or cmd.strip().endswith(p) for p in CRITICAL_PATHS)

def learn_pattern(memory, wrong, correct):
    if is_dangerous_command(correct):
        return
    if escalates_privilege(wrong, correct):
        return
    if touches_critical_path(correct):
        return

    w_norm = normalize(wrong)
    c_norm = normalize(correct)

    entry = memory["patterns"].setdefault(w_norm, {
        "correct": c_norm,
        "count": 0,
        "last_seen": 0
    })

    entry["count"] += 1
    entry["last_seen"] = int(time.time())

def apply_patterns(memory, command):
    cmd_norm = normalize(command)

    for pattern, data in memory["patterns"].items():
        score = similarity(cmd_norm, pattern)
        if score > 0.75:
            confidence = compute_confidence(data["count"], data["last_seen"])
            if confidence < MIN_CONFIDENCE:
                continue

            suggestion = command.replace(
                command.split()[0],
                data["correct"].split()[0],
                1
            )

            return {
                "intent": "Learned correction pattern",
                "risk": "Low",
                "reason": "Based on past safe corrections (time-decayed)",
                "suggestion": suggestion,
                "confidence": confidence
            }
    return None

def command_exists(cmd):
    return shutil.which(cmd) is not None

def analyze(command, memory):
    learned = apply_patterns(memory, command)
    if learned:
        return learned

    for p in DANGEROUS_PATTERNS:
        if p in command:
            return {
                "intent": "Destructive system command",
                "risk": "Critical",
                "reason": f"Matched dangerous pattern: {p}",
                "suggestion": "Do NOT run unless you fully understand the impact"
            }

    tokens = command.split()
    first = tokens[0] if tokens else ""

    if not command_exists(first) and first not in COMMON_COMMANDS:
        return {
            "intent": "Likely typing error",
            "risk": "Low",
            "reason": f"'{first}' is not a known command",
            "suggestion": "Check spelling or use a known command"
        }

    return {
        "intent": "Normal system command",
        "risk": "Low",
        "reason": "Command appears valid",
        "suggestion": "Safe to proceed"
    }

def main():
    command = " ".join(sys.argv[1:])
    memory = load_memory()

    prune_patterns(memory)
    result = analyze(command, memory)

    memory["history"].append({
        "command": command,
        "intent": result["intent"],
        "time": int(time.time())
    })
    memory["history"] = memory["history"][-50:]

    if len(memory["history"]) >= 2:
        prev = memory["history"][-2]
        curr = memory["history"][-1]
        if prev["intent"] == "Likely typing error" and curr["intent"] == "Normal system command":
            learn_pattern(memory, prev["command"], curr["command"])

    save_memory(memory)

    print("Intent:", result["intent"])
    print("Risk level:", result["risk"])
    print("Reason:")
    print(" ", result["reason"])
    print("Suggested action:")
    print(" ", result["suggestion"])
    if "confidence" in result:
        print("Confidence:", result["confidence"])

if __name__ == "__main__":
    main()
PYCODE

chmod +x "$CORE_DIR/intent.py"

# 4. Install CLI
echo "[+] Installing CLI..."
cat > "$BIN_DIR/ai" <<'BASHCODE'
#!/usr/bin/env bash
set -e
python3 "$HOME/linux_ai/core/intent.py" "$@"
BASHCODE

chmod +x "$BIN_DIR/ai"

# 5. Ensure PATH
if ! grep -q 'linux_ai/bin' "$HOME/.zshrc"; then
  echo 'export PATH="$HOME/linux_ai/bin:$PATH"' >> "$HOME/.zshrc"
fi

echo "=== Installation complete ==="
echo "Restart your shell or run: exec zsh"
