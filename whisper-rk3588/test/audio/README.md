# Test Audio Directory

Place your test audio files here.

## Default Test File

The default test file is `test1.mp3`. Place your audio file here:

```
test/audio/test1.mp3
```

Then run:

```bash
./scripts/test_single.sh
```

## Supported Formats

- WAV (recommended)
- MP3
- FLAC
- OGG

## Audio Requirements

- **Sample Rate**: 16000 Hz (will be auto-resampled)
- **Channels**: Mono (will be auto-converted)
- **Duration**: Max 20 seconds for base model

## Examples

```bash
# Test default audio
./scripts/test_single.sh

# Test with specific audio
./scripts/test_single.sh -a test/audio/your_audio.mp3

# Test Chinese audio
./scripts/test_single.sh -a test/audio/chinese.mp3 -t zh
```
