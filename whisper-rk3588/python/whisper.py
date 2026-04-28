import numpy as np
import argparse
import soundfile as sf
import scipy
import scipy.signal
import os

RKNN_LITE = False
RKNN = None

try:
    from rknn.api import RKNN
    RKNN_LITE = False
except ImportError:
    try:
        from rknnlite.api import RKNNLite as RKNN
        RKNN_LITE = True
    except ImportError:
        pass

SAMPLE_RATE = 16000
N_FFT = 400
HOP_LENGTH = 160
CHUNK_LENGTH = 20
N_SAMPLES = CHUNK_LENGTH * SAMPLE_RATE
MAX_LENGTH = CHUNK_LENGTH * 100
N_MELS = 80

LANG_TOKENS = {
    'en': 50259,
    'zh': 50260,
    'de': 50261,
    'es': 50262,
    'ru': 50263,
    'ko': 50264,
    'fr': 50265,
    'ja': 50266,
    'pt': 50267,
    'tr': 50268,
    'pl': 50269,
    'ca': 50270,
    'nl': 50271,
    'ar': 50272,
    'sv': 50273,
    'it': 50274,
    'id': 50275,
    'hi': 50276,
    'fi': 50277,
    'vi': 50278,
    'he': 50279,
    'uk': 50280,
    'el': 50281,
    'ms': 50282,
    'cs': 50283,
    'ro': 50284,
    'da': 50285,
    'hu': 50286,
    'ta': 50287,
    'no': 50288,
    'th': 50289,
    'ur': 50290,
    'hr': 50291,
    'bg': 50292,
    'lt': 50293,
    'la': 50294,
    'mi': 50295,
    'ml': 50296,
    'cy': 50297,
    'sk': 50298,
    'te': 50299,
    'fa': 50300,
    'lv': 50301,
    'bn': 50302,
    'sr': 50303,
    'az': 50304,
    'sl': 50305,
    'kn': 50306,
    'et': 50307,
    'mk': 50308,
    'br': 50309,
    'eu': 50310,
    'is': 50311,
    'hy': 50312,
    'ne': 50313,
    'mn': 50314,
    'bs': 50315,
    'kk': 50316,
    'sq': 50317,
    'sw': 50318,
    'gl': 50319,
    'mr': 50320,
    'pa': 50321,
    'si': 50322,
    'km': 50323,
    'sn': 50324,
    'yo': 50325,
    'so': 50326,
    'af': 50327,
    'oc': 50328,
    'lo': 50329,
    'ka': 50330,
    'be': 50331,
    'tg': 50332,
    'sd': 50333,
    'gu': 50334,
    'am': 50335,
    'yi': 50336,
    'lo': 50337,
    'uz': 50338,
    'fo': 50339,
    'ht': 50340,
    'ps': 50341,
    'tk': 50342,
    'nn': 50343,
    'mt': 50344,
    'sa': 50345,
    'lb': 50346,
    'my': 50347,
    'bo': 50348,
    'tl': 50349,
    'mg': 50350,
    'as': 50351,
    'tt': 50352,
    'haw': 50353,
    'ln': 50354,
    'ha': 50355,
    'ba': 50356,
    'jw': 50357,
    'su': 50358,
}


def ensure_sample_rate(waveform, original_sample_rate, desired_sample_rate=16000):
    if original_sample_rate != desired_sample_rate:
        print("resample_audio: {} HZ -> {} HZ".format(original_sample_rate, desired_sample_rate))
        desired_length = int(round(float(len(waveform)) / original_sample_rate * desired_sample_rate))
        waveform = scipy.signal.resample(waveform, desired_length)
    return waveform, desired_sample_rate


def ensure_channels(waveform, original_channels, desired_channels=1):
    if original_channels != desired_channels:
        print("convert_channels: {} -> {}".format(original_channels, desired_channels))
        waveform = np.mean(waveform, axis=1)
    return waveform, desired_channels


def get_char_index(c):
    if 'A' <= c <= 'Z':
        return ord(c) - ord('A')
    elif 'a' <= c <= 'z':
        return ord(c) - ord('a') + (ord('Z') - ord('A') + 1)
    elif '0' <= c <= '9':
        return ord(c) - ord('0') + (ord('Z') - ord('A')) + (ord('z') - ord('a')) + 2
    elif c == '+':
        return 62
    elif c == '/':
        return 63
    else:
        return 0


def base64_decode(encoded_string):
    if not encoded_string:
        return ""
    
    encoded_string = encoded_string.strip()
    if len(encoded_string) < 2:
        return encoded_string
    
    output_length = len(encoded_string) // 4 * 3
    if output_length == 0:
        return encoded_string
    
    decoded_string = bytearray(output_length)
    
    index = 0
    output_index = 0
    while index < len(encoded_string):
        if encoded_string[index] == '=':
            break

        first_byte = (get_char_index(encoded_string[index]) << 2) + ((get_char_index(encoded_string[index + 1]) & 0x30) >> 4)
        decoded_string[output_index] = first_byte

        if index + 2 < len(encoded_string) and encoded_string[index + 2] != '=':
            second_byte = ((get_char_index(encoded_string[index + 1]) & 0x0f) << 4) + ((get_char_index(encoded_string[index + 2]) & 0x3c) >> 2)
            decoded_string[output_index + 1] = second_byte

            if index + 3 < len(encoded_string) and encoded_string[index + 3] != '=':
                third_byte = ((get_char_index(encoded_string[index + 2]) & 0x03) << 6) + get_char_index(encoded_string[index + 3])
                decoded_string[output_index + 2] = third_byte
                output_index += 3
            else:
                output_index += 2
        else:
            output_index += 1

        index += 4
            
    return decoded_string.decode('utf-8', errors='replace')


def read_vocab(vocab_path):
    with open(vocab_path, 'r') as f:
        vocab = {}
        for line in f:
            if len(line.strip().split(' ')) < 2:
                key = line.strip().split(' ')[0]
                value = ""
            else:
                key, value = line.strip().split(' ')
            vocab[key] = value
    return vocab


def pad_or_trim(audio_array, max_length=MAX_LENGTH):
    x_mel = np.zeros((N_MELS, max_length), dtype=np.float32)
    real_length = audio_array.shape[1] if audio_array.shape[1] <= max_length else max_length
    x_mel[:, :real_length] = audio_array[:, :real_length]
    return x_mel


def mel_filters(n_mels, model_dir):
    assert n_mels in {80}, f"Unsupported n_mels: {n_mels}"
    filters_path = os.path.join(model_dir, "mel_80_filters.txt")
    mels_data = np.loadtxt(filters_path, dtype=np.float32).reshape((80, 201))
    return mels_data


def log_mel_spectrogram(audio, n_mels, model_dir, padding=0):
    if padding > 0:
        audio = np.pad(audio, (0, padding), mode='constant')

    window = np.hanning(N_FFT).astype(audio.dtype)
    
    f, t, Zxx = scipy.signal.stft(audio, fs=SAMPLE_RATE, window=window, nperseg=N_FFT, noverlap=N_FFT - HOP_LENGTH)
    magnitudes = np.abs(Zxx) ** 2

    filters = mel_filters(n_mels, model_dir)
    mel_spec = filters @ magnitudes

    log_spec = np.clip(mel_spec, a_min=1e-10, a_max=None)
    log_spec = np.log10(log_spec)
    log_spec = np.maximum(log_spec, log_spec.max() - 8.0)
    log_spec = (log_spec + 4.0) / 4.0
    return log_spec


def run_encoder(encoder_model, in_encoder):
    if hasattr(encoder_model, 'inference'):
        out_encoder = encoder_model.inference(inputs=[in_encoder])[0]
    else:
        out_encoder = encoder_model.run(None, {"x": in_encoder})[0]
    return out_encoder


def _decode(decoder_model, tokens, out_encoder):
    if hasattr(decoder_model, 'inference'):
        out_decoder = decoder_model.inference([np.asarray([tokens], dtype="int64"), out_encoder])[0]
    else:
        out_decoder = decoder_model.run(None, {"tokens": np.asarray([tokens], dtype="int64"), "audio": out_encoder})[0]
    return out_decoder


def detect_language(decoder_model, out_encoder, vocab):
    tokens = [50258, 50359, 50363]
    out_decoder = _decode(decoder_model, tokens, out_encoder)
    
    lang_probs = out_decoder[0, -1]
    
    best_lang_token = None
    best_prob = -1
    for lang, token in LANG_TOKENS.items():
        if token < len(lang_probs):
            prob = lang_probs[token]
            if prob > best_prob:
                best_prob = prob
                best_lang_token = token
                best_lang = lang
    
    return best_lang, best_lang_token


def run_decoder(decoder_model, out_encoder, vocab, task_code, auto_detect=False):
    end_token = 50257
    
    if auto_detect:
        detected_lang, detected_code = detect_language(decoder_model, out_encoder, vocab)
        print(f"Detected language: {detected_lang}")
        task_code = detected_code
    
    tokens = [50258, task_code, 50359, 50363]
    timestamp_begin = 50364

    max_tokens = 12
    tokens_str = ''
    pop_id = max_tokens

    tokens = tokens * int(max_tokens/4)
    next_token = 50258

    while next_token != end_token:
        out_decoder = _decode(decoder_model, tokens, out_encoder)
        next_token = out_decoder[0, -1].argmax()
        next_token_str = vocab.get(str(next_token), "")
        tokens.append(next_token)

        if next_token == end_token:
            tokens.pop(-1)
            break
        if next_token > timestamp_begin:
            continue
        if pop_id > 4:
            pop_id -= 1

        tokens.pop(pop_id)
        tokens_str += next_token_str

    result = tokens_str.replace('\u0120', ' ').replace('##', '').replace('\n', '')
    
    if task_code == 50260:
        try:
            result = base64_decode(result)
        except:
            pass
    
    return result


def init_model(model_path, target=None, device_id=None):
    if model_path.endswith(".rknn"):
        if RKNN is None:
            print("Error: Neither rknn-toolkit2 nor rknn-toolkit-lite2 is installed!")
            exit(1)
        
        model = RKNN()

        print('--> Loading model')
        ret = model.load_rknn(model_path)
        if ret != 0:
            print('Load RKNN model "{}" failed!'.format(model_path))
            exit(ret)
        print('done')

        print('--> Init runtime environment')
        if RKNN_LITE:
            ret = model.init_runtime(core_mask=RKNN.NPU_CORE_0)
        else:
            ret = model.init_runtime(target=target, device_id=device_id)
        if ret != 0:
            print('Init runtime environment failed')
            exit(ret)
        print('done')

    return model


def release_model(model):
    if hasattr(model, 'release'):
        model.release()
    model = None


class WhisperModel:
    def __init__(self, encoder_path, decoder_path, target='rk3588', device_id=None, model_dir=None):
        if model_dir is None:
            model_dir = os.path.dirname(encoder_path)
        
        self.model_dir = model_dir
        self.target = target
        self.device_id = device_id
        
        print("Loading encoder model...")
        self.encoder_model = init_model(encoder_path, target, device_id)
        print("Loading decoder model...")
        self.decoder_model = init_model(decoder_path, target, device_id)
        
    def transcribe(self, audio_path, task='en', auto_detect=False):
        if task == 'auto':
            auto_detect = True
            task_code = 50259
            vocab_name = "vocab_en.txt"
        elif task in LANG_TOKENS:
            task_code = LANG_TOKENS[task]
            vocab_name = "vocab_zh.txt" if task == 'zh' else "vocab_en.txt"
        else:
            print(f"Unknown task: {task}, using 'en'")
            task_code = 50259
            vocab_name = "vocab_en.txt"
        
        vocab_path = os.path.join(self.model_dir, vocab_name)
            
        vocab = read_vocab(vocab_path)
        audio_data, sample_rate = sf.read(audio_path)
        channels = audio_data.ndim
        audio_data, channels = ensure_channels(audio_data, channels)
        audio_data, sample_rate = ensure_sample_rate(audio_data, sample_rate)
        
        audio_array = np.array(audio_data, dtype=np.float32)
        audio_array = log_mel_spectrogram(audio_array, N_MELS, self.model_dir)
        
        total_frames = audio_array.shape[1]
        frame_per_chunk = CHUNK_LENGTH * SAMPLE_RATE // HOP_LENGTH
        
        if total_frames <= MAX_LENGTH:
            x_mel = pad_or_trim(audio_array)
            x_mel = np.expand_dims(x_mel, 0)
            out_encoder = run_encoder(self.encoder_model, x_mel)
            result = run_decoder(self.decoder_model, out_encoder, vocab, task_code, auto_detect)
        else:
            result = ""
            num_chunks = (total_frames + frame_per_chunk - 1) // frame_per_chunk
            print(f"Audio too long, processing {num_chunks} chunks...")
            
            for i in range(num_chunks):
                start = i * frame_per_chunk
                end = min(start + MAX_LENGTH, total_frames)
                chunk = audio_array[:, start:end]
                x_mel = pad_or_trim(chunk)
                x_mel = np.expand_dims(x_mel, 0)
                
                out_encoder = run_encoder(self.encoder_model, x_mel)
                chunk_result = run_decoder(self.decoder_model, out_encoder, vocab, task_code, auto_detect if i == 0 else False)
                if chunk_result:
                    result += chunk_result + " "
        
        return result.strip()
    
    def release(self):
        release_model(self.encoder_model)
        release_model(self.decoder_model)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Whisper Python Demo', add_help=True)
    parser.add_argument('--encoder_model', type=str, required=True, help='encoder model path')
    parser.add_argument('--decoder_model', type=str, required=True, help='decoder model path')
    parser.add_argument('--audio', type=str, required=True, help='audio path')
    parser.add_argument('--task', type=str, default='en', help='recognition task: en, zh, auto (auto-detect)')
    parser.add_argument('--target', type=str, default='rk3588', help='target RKNPU platform')
    parser.add_argument('--device_id', type=str, default=None, help='device id')
    parser.add_argument('--model_dir', type=str, default=None, help='model directory')
    args = parser.parse_args()

    model_dir = args.model_dir if args.model_dir else os.path.dirname(args.encoder_model)
    
    model = WhisperModel(
        encoder_path=args.encoder_model,
        decoder_path=args.decoder_model,
        target=args.target,
        device_id=args.device_id,
        model_dir=model_dir
    )
    
    result = model.transcribe(args.audio, args.task)
    print("\nWhisper output:", result)
    
    model.release()
