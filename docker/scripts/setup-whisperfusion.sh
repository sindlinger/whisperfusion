#!/bin/bash -e

# Clone this repo and install requirements
[ -d "WhisperFusion" ] || git clone https://github.com/Collabora/WhisperFusion.git

cd WhisperFusion

# Install system dependencies
apt update
apt install ffmpeg portaudio19-dev -y

# Remove versões conflitantes
pip uninstall -y tokenizers transformers huggingface_hub

# Instale versões específicas e mais antigas que sabemos que são compatíveis
pip install huggingface_hub==0.14.1
pip install tokenizers==0.13.3
pip install transformers==4.31.0

# Instale as dependências do whisperspeech primeiro
pip install fastcore
pip install fastprogress
pip install "speechbrain<1.0"
pip install vocos
pip install whisperspeech==0.8.9

# Agora instale o resto das dependências, exceto as que já instalamos
pip install --no-deps -r requirements.txt

# Instale dependências adicionais que podem ser necessárias
pip install torch torchaudio

# Download dos modelos usando huggingface_hub
python3 -c "
from huggingface_hub import hf_hub_download
import os

# Download whisperspeech models
hf_hub_download('collabora/whisperspeech', 't2s-small-en+pl.model')
hf_hub_download('collabora/whisperspeech', 's2a-q4-tiny-en+pl.model')

# Download vocos model
hf_hub_download('charactr/vocos-encodec-24khz', 'pytorch_model.bin')
hf_hub_download('charactr/vocos-encodec-24khz', 'config.yaml')
"

# Setup cache directories and download additional models
mkdir -p /root/.cache/torch/hub/checkpoints/
curl -L -o /root/.cache/torch/hub/checkpoints/encodec_24khz-d7cc33bc.th https://dl.fbaipublicfiles.com/encodec/v0/encodec_24khz-d7cc33bc.th

mkdir -p /root/.cache/whisper-live/
curl -L -o /root/.cache/whisper-live/silero_vad.onnx https://github.com/snakers4/silero-vad/raw/v4.0/files/silero_vad.onnx

# Configure o cache do transformers antes de tentar movê-lo
export TRANSFORMERS_CACHE="/root/.cache/huggingface/transformers"
mkdir -p $TRANSFORMERS_CACHE

# Move the transformers cache
python3 -c 'from transformers.utils.hub import move_cache; move_cache()'