# Test Output Directory

This directory contains generated audio files from TTS tests.

## Directory Structure

```
output/
├── eng/           # English TTS outputs
│   ├── single_*.wav
│   ├── test_*.wav
│   └── batch_*.wav
├── zho/           # Chinese TTS outputs
├── deu/           # German TTS outputs
├── fra/           # French TTS outputs
└── ...            # Other languages
```

## File Naming Convention

- `single_*.wav` - Single test outputs
- `test_N_*.wav` - Multi-test outputs (N = test case number)
- `batch_N_*.wav` - Batch test outputs (N = line number in text file)

## Download Outputs

From RK3576 device to local machine:

```bash
# Download all outputs
scp -r user@192.168.1.100:/path/to/mms_tts-rk3576/test/output .

# Download specific language
scp -r user@192.168.1.100:/path/to/mms_tts-rk3576/test/output/eng .
```
