#!/bin/bash
# MyVampire — Party AI Training Script
# Usage:
#   ./tools/train.sh                    → new run with auto timestamp ID
#   ./tools/train.sh MyRun1             → new run with custom ID
#   ./tools/train.sh MyRun1 --resume    → resume a previous run

set -e

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV="$PROJECT_ROOT/ml-agents-env"
CONFIG="$PROJECT_ROOT/config/party_ai_trainer.yaml"
RESULTS="$PROJECT_ROOT/training-results"
MLAGENTS="$VENV/bin/mlagents-learn"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}   MyVampire — Party AI Training           ${NC}"
echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}"
echo ""

# ── Argument parsing ──────────────────────────────────────────────────────────
RUN_ID="${1:-PartyAI_$(date +%Y%m%d_%H%M%S)}"
RESUME_ARG="${2:-}"

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [ ! -f "$MLAGENTS" ]; then
    echo -e "${RED}ERROR: mlagents-learn not found at:${NC}"
    echo "  $MLAGENTS"
    echo ""
    echo "Fix it by running:"
    echo "  cd $PROJECT_ROOT"
    echo "  python3 -m venv ml-agents-env"
    echo "  ml-agents-env/bin/pip install mlagents==1.1.0"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo -e "${RED}ERROR: Training config not found at:${NC}"
    echo "  $CONFIG"
    exit 1
fi

# ── Run mode ──────────────────────────────────────────────────────────────────
if [ "$RESUME_ARG" = "--resume" ] && [ -d "$RESULTS/$RUN_ID" ]; then
    MODE_FLAG="--resume"
    echo -e "${YELLOW}Mode: RESUME previous run${NC}"
else
    MODE_FLAG="--force"
    echo -e "${GREEN}Mode: NEW run${NC}"
fi

echo -e "${GREEN}Run ID:${NC}  $RUN_ID"
echo -e "${GREEN}Config:${NC}  $CONFIG"
echo -e "${GREEN}Output:${NC}  $RESULTS/$RUN_ID/"
echo ""

# ── Unity instructions ────────────────────────────────────────────────────────
echo -e "${YELLOW}${BOLD}BEFORE YOU CONTINUE — do this in Unity:${NC}"
echo ""
echo -e "  ${BOLD}1.${NC} Open Unity Editor"
echo -e "  ${BOLD}2.${NC} File → Open Scene → Assets/Scenes/TrainingScene.unity"
echo -e "  ${BOLD}3.${NC} ${RED}Do NOT press Play yet${NC} — wait until you see:"
echo -e "     ${BOLD}'Listening on port 5004'${NC}  in this terminal"
echo -e "  ${BOLD}4.${NC} When you see that message, press Play in Unity"
echo ""
echo -e "${YELLOW}If the TrainingScene is not set up yet, see:${NC}"
echo -e "  ${BOLD}tools/TRAINING-SETUP.md${NC}  for step-by-step instructions"
echo ""

read -p "Press Enter when Unity is open and TrainingScene is loaded..."
echo ""

# ── Start training ────────────────────────────────────────────────────────────
echo -e "${GREEN}Starting ML-Agents trainer...${NC}"
echo -e "${YELLOW}→ Watch for 'Listening on port 5004', then press Play in Unity${NC}"
echo ""

"$MLAGENTS" \
    "$CONFIG" \
    --run-id="$RUN_ID" \
    --results-dir="$RESULTS" \
    $MODE_FLAG

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Training complete!${NC}"
echo -e "Model saved to: ${BOLD}$RESULTS/$RUN_ID/${NC}"
echo ""
echo "To use the trained model in Unity:"
echo "  1. Copy $RESULTS/$RUN_ID/PartyAI.onnx  →  Assets/Models/PartyAI.onnx"
echo "  2. In Unity Inspector, assign it to RLPartyAgent → Model field"
echo "  3. Set Behavior Type to 'Inference Only'"
