#!/bin/bash
#
# Setup script for nano-codec-dataset-pipeline (RunPod style)
# Compatible with RunPod PyTorch 2.6.0 + CUDA 12.6
#
# NO virtual environments - installs globally
# Assumes PyTorch already installed (comes with RunPod)
# Installs: NeMo Toolkit, torchaudio, torchvision, torchcodec + dependencies
#

set -e  # Exit on error

# -------- COLORS --------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# -------- HEADER --------
clear
echo -e "${CYAN}${BOLD}"
echo "==============================================="
echo "          N I N E N I N E S I X  😼"
echo "==============================================="
echo ""
echo -e "${MAGENTA}"
echo "          /\\_/\\  "
echo "         ( -.- )───┐"
echo "          > ^ <    │"
echo -e "${CYAN}"
echo "==============================================="
echo -e "${NC}"
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   Nano Codec Dataset Pipeline - Setup Script              ║${NC}"
echo -e "${GREEN}${BOLD}║   (RunPod compatible - no venv)                            ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# -------- STEP 1: Check Python --------
echo -e "${GREEN}${BOLD}[STEP 1/6] Verificant Python...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 no trobat!${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

echo -e "${BLUE}Python $PYTHON_VERSION detectat${NC}"

if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 10 ]; then
    echo -e "${GREEN}✓ Python version compatible (3.10+)${NC}"
else
    echo -e "${RED}❌ Python 3.10+ requerit!${NC}"
    exit 1
fi
echo ""

# -------- STEP 2: Install system dependencies --------
echo -e "${GREEN}${BOLD}[STEP 2/6] Instal·lant dependències del sistema...${NC}"

echo -e "${BLUE}📦 Actualitzant llistes de paquets...${NC}"
apt update -qq

echo -e "${BLUE}📦 Instal·lant llibreries d'àudio (libsndfile1, ffmpeg)...${NC}"
apt install -y -qq libsndfile1 ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswresample-dev

# Instal·la dev packages per Python
if [ "$PYTHON_MINOR" -eq 12 ]; then
    apt install -y -qq python3.12-dev libpython3.12-dev
elif [ "$PYTHON_MINOR" -eq 11 ]; then
    apt install -y -qq python3.11-dev libpython3.11-dev
elif [ "$PYTHON_MINOR" -eq 10 ]; then
    apt install -y -qq python3.10-dev libpython3.10-dev
else
    apt install -y -qq python3-dev libpython3-dev
fi

echo -e "${GREEN}✓ Dependències del sistema instal·lades${NC}"
echo ""

# -------- STEP 3: Verify PyTorch --------
echo -e "${GREEN}${BOLD}[STEP 3/6] Verificant PyTorch...${NC}"
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'CUDA available: {torch.cuda.is_available()}')" || {
    echo -e "${RED}❌ PyTorch no trobat!${NC}"
    echo -e "${YELLOW}A RunPod, PyTorch hauria d'estar pre-instal·lat.${NC}"
    exit 1
}
echo -e "${GREEN}✓ PyTorch disponible${NC}"
echo ""

# -------- STEP 4: Install torchaudio, torchvision, torchcodec --------
echo -e "${GREEN}${BOLD}[STEP 4/6] Instal·lant torchaudio, torchvision i torchcodec...${NC}"

# Detecta versió CUDA
CUDA_VER=$(python -c "import torch; print(torch.version.cuda.replace('.', '')[:4] if torch.version.cuda else 'cpu')" 2>/dev/null || echo "cpu")
echo -e "${BLUE}🎮 CUDA detectada: ${CUDA_VER}${NC}"

if [[ "$CUDA_VER" == "cpu" ]]; then
    echo -e "${YELLOW}⚠️  Mode CPU detectat${NC}"
    pip install --upgrade torchaudio torchvision
else
    echo -e "${BLUE}📦 Instal·lant per CUDA ${CUDA_VER}...${NC}"
    pip install --upgrade torchaudio torchvision \
      --index-url https://download.pytorch.org/whl/cu${CUDA_VER} || {
        echo -e "${YELLOW}⚠️  Error amb cu${CUDA_VER}, provant amb cu126...${NC}"
        pip install --upgrade torchaudio torchvision \
          --index-url https://download.pytorch.org/whl/cu126
    }

    # Instal·la torchcodec (opcional)
    echo -e "${BLUE}📦 Instal·lant torchcodec...${NC}"
    pip install --upgrade --no-cache-dir torchcodec \
      --index-url https://download.pytorch.org/whl/cu${CUDA_VER} 2>/dev/null || {
        echo -e "${YELLOW}⚠️  torchcodec no disponible (no és crític)${NC}"
    }
fi

echo -e "${GREEN}✓ Llibreries d'àudio instal·lades${NC}"
echo ""

# -------- STEP 5: Install NeMo Toolkit (CRITICAL) --------
echo -e "${GREEN}${BOLD}[STEP 5/6] Instal·lant NeMo Toolkit (CRÍTIC per NanoCodec)...${NC}"
echo -e "${YELLOW}ℹ️  Això pot trigar diversos minuts...${NC}"

pip install -q "nemo_toolkit[all]>=2.0.0" || {
    echo -e "${RED}❌ Error instal·lant NeMo Toolkit!${NC}"
    echo -e "${YELLOW}Provant sense [all]...${NC}"
    pip install -q "nemo_toolkit>=2.0.0"
}

# Verifica NeMo
echo -e "${BLUE}🔍 Verificant NeMo Toolkit...${NC}"
python -c "import nemo; from nemo.collections.tts.models import AudioCodecModel; print(f'✅ NeMo Toolkit {nemo.__version__}')" || {
    echo -e "${RED}❌ NeMo Toolkit no funciona correctament!${NC}"
    exit 1
}

echo -e "${GREEN}✓ NeMo Toolkit instal·lat i verificat${NC}"
echo ""

# -------- STEP 6: Install other dependencies --------
echo -e "${GREEN}${BOLD}[STEP 6/6] Instal·lant altres dependències...${NC}"
echo -e "${BLUE}📦 datasets, omegaconf, huggingface-hub, librosa...${NC}"

pip install -q \
    "datasets>=2.14.0" \
    "omegaconf>=2.3.0" \
    "huggingface-hub>=0.19.0" \
    "librosa>=0.10.0" \
    "soundfile>=0.12.0" \
    "audioread>=3.0.0" \
    "numpy>=1.24.0" \
    "pandas>=2.0.0" \
    "tqdm>=4.65.0" \
    "pyyaml>=6.0"

# hf_transfer per descàrregues ràpides
pip install -q hf_transfer && {
    echo -e "${GREEN}✓ hf_transfer instal·lat (descàrregues 10x més ràpides)${NC}"
    if ! grep -q "HF_HUB_ENABLE_HF_TRANSFER" ~/.bashrc 2>/dev/null; then
        echo 'export HF_HUB_ENABLE_HF_TRANSFER=1' >> ~/.bashrc
    fi
    export HF_HUB_ENABLE_HF_TRANSFER=1
} || {
    echo -e "${YELLOW}⚠️  hf_transfer no instal·lat (no és crític)${NC}"
}

echo -e "${GREEN}✓ Dependències addicionals instal·lades${NC}"
echo ""

# -------- VERIFICATION --------
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   Verificant instal·lació completa...                     ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

python - <<'PY'
import sys
errors = []

# PyTorch
try:
    import torch
    print(f"✅ PyTorch:      {torch.__version__} (CUDA: {torch.version.cuda})")
except Exception as e:
    errors.append(f"PyTorch: {e}")

# Audio libraries
try:
    import torchaudio
    import torchvision
    print(f"✅ Torchaudio:   {torchaudio.__version__}")
    print(f"✅ Torchvision:  {torchvision.__version__}")
except Exception as e:
    errors.append(f"Audio libraries: {e}")

# NeMo (CRITICAL)
try:
    import nemo
    from nemo.collections.tts.models import AudioCodecModel
    print(f"✅ NeMo Toolkit: {nemo.__version__}")
except Exception as e:
    errors.append(f"NeMo Toolkit: {e}")

# Datasets
try:
    import datasets
    import omegaconf
    print(f"✅ Datasets:     {datasets.__version__}")
    print(f"✅ OmegaConf:    {omegaconf.__version__}")
except Exception as e:
    errors.append(f"Datasets/Config: {e}")

# Audio processing
try:
    import librosa
    import soundfile
    print(f"✅ Librosa:      {librosa.__version__}")
    print(f"✅ Soundfile:    {soundfile.__version__}")
except Exception as e:
    errors.append(f"Audio processing: {e}")

# Optional
try:
    import torchcodec
    print(f"✅ Torchcodec:   {torchcodec.__version__}")
except:
    print(f"⚠️  Torchcodec:   not installed (optional)")

if errors:
    print("\n❌ ERRORS:")
    for err in errors:
        print(f"   {err}")
    sys.exit(1)
PY

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Hi ha errors a la instal·lació!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   Setup completat amb èxit! 🎉                            ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 Resum:${NC}"
echo -e "   ✅ PyTorch (pre-instal·lat a RunPod)"
echo -e "   ✅ torchaudio, torchvision, torchcodec"
echo -e "   ✅ NeMo Toolkit (amb NanoCodec)"
echo -e "   ✅ datasets, omegaconf, huggingface-hub"
echo -e "   ✅ Llibreries d'àudio (librosa, soundfile)"
echo -e "   ✅ hf_transfer (descàrregues ràpides)"
echo ""

# Print logo
echo -e "${CYAN}${BOLD}"
echo "==============================================="
echo "          N I N E N I N E S I X  😼"
echo "==============================================="
echo -e "${NC}"
echo ""

echo -e "${YELLOW}📝 Passos següents:${NC}"
echo ""
echo -e "${CYAN}1. Configura HuggingFace:${NC}"
echo -e "   ${GREEN}git config --global credential.helper store${NC}"
echo -e "   ${GREEN}huggingface-cli login${NC}"
echo ""
echo -e "${CYAN}2. Configura el pipeline:${NC}"
echo -e "   ${GREEN}nano config.yaml${NC}"
echo -e "   (o config_balear.yaml per datasets balear)"
echo ""
echo -e "${CYAN}3. Executa el pipeline:${NC}"
echo -e "   ${GREEN}python main.py${NC}"
echo ""
echo -e "${BLUE}💡 Veure README.md per més informació${NC}"
echo ""
