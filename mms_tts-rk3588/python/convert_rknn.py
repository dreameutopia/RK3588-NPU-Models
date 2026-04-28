#!/usr/bin/env python3
"""
MMS-TTS RKNN Conversion Script
Convert ONNX encoder and decoder models to RKNN format for RK3588
"""

import os
import sys
import argparse

def convert_onnx_to_rknn(onnx_path, output_path, target_platform="rk3588"):
    try:
        from rknn.api import RKNN
    except ImportError:
        print("Error: rknn-toolkit2 not installed!")
        print("Please install with: pip install rknn-toolkit2")
        sys.exit(1)

    if not os.path.exists(onnx_path):
        print(f"Error: ONNX model not found: {onnx_path}")
        sys.exit(1)

    rknn = RKNN(verbose=True)

    print(f"--> Config model for {target_platform}")
    rknn.config(
        target_platform=target_platform,
        single_core_mode=False,
    )
    print("done")

    print(f"--> Loading ONNX model: {onnx_path}")
    ret = rknn.load_onnx(model=onnx_path)
    if ret != 0:
        print(f"Load ONNX model failed! ret={ret}")
        sys.exit(ret)
    print("done")

    print("--> Building RKNN model...")
    ret = rknn.build(do_quantization=False)
    if ret != 0:
        print(f"Build failed with ret={ret}")
        sys.exit(ret)
    print("done")

    print(f"--> Exporting RKNN model: {output_path}")
    ret = rknn.export_rknn(output_path)
    if ret != 0:
        print(f"Export RKNN model failed! ret={ret}")
        sys.exit(ret)
    print("done")

    rknn.release()
    print(f"RKNN model saved to: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Convert MMS-TTS ONNX to RKNN")
    parser.add_argument("--encoder", type=str, help="Path to encoder ONNX model")
    parser.add_argument("--decoder", type=str, help="Path to decoder ONNX model")
    parser.add_argument("--target", type=str, default="rk3588", 
                        help="Target platform (rk3588, rk3576, etc.)")
    parser.add_argument("--output_dir", type=str, default="model",
                        help="Output directory for RKNN models")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    print("=" * 60)
    print("MMS-TTS RKNN Converter")
    print(f"Target: {args.target}")
    print("=" * 60)
    print()

    if args.encoder:
        encoder_output = os.path.join(args.output_dir, os.path.basename(args.encoder).replace(".onnx", ".rknn"))
        print(f"\n[1/2] Converting encoder...")
        convert_onnx_to_rknn(args.encoder, encoder_output, args.target)
    
    if args.decoder:
        decoder_output = os.path.join(args.output_dir, os.path.basename(args.decoder).replace(".onnx", ".rknn"))
        print(f"\n[2/2] Converting decoder...")
        convert_onnx_to_rknn(args.decoder, decoder_output, args.target)

    print("\n" + "=" * 60)
    print("Conversion completed!")
    print("=" * 60)
    print("\nNext steps:")
    print("  python3 python/mms_tts.py --encoder model/mms_tts_eng_encoder.rknn --decoder model/mms_tts_eng_decoder.rknn --text 'Hello world'")


if __name__ == "__main__":
    main()
