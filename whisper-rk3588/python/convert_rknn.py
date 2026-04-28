import sys
import os
import argparse
from rknn.api import RKNN

DEFAULT_QUANT = False


def convert_onnx_to_rknn(onnx_path, platform, do_quant=False, output_path=None):
    if output_path is None:
        output_path = onnx_path.replace('.onnx', '.rknn')
    
    print(f"\nConverting {onnx_path} to {output_path}...")
    print(f"  Platform: {platform}")
    print(f"  Quantization: {'Enabled' if do_quant else 'Disabled'}")
    
    rknn = RKNN(verbose=False)

    print('--> Config model')
    rknn.config(target_platform=platform)
    print('done')

    print('--> Loading model')
    ret = rknn.load_onnx(model=onnx_path)
    if ret != 0:
        print('Load model failed!')
        return None
    print('done')

    print('--> Building model')
    ret = rknn.build(do_quantization=do_quant)
    if ret != 0:
        print('Build model failed!')
        return None
    print('done')

    print('--> Export rknn model')
    ret = rknn.export_rknn(output_path)
    if ret != 0:
        print('Export rknn model failed!')
        return None
    print('done')

    rknn.release()
    
    print(f"Successfully converted to {output_path}")
    return output_path


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert ONNX model to RKNN for RK3588')
    parser.add_argument('--onnx', type=str, required=True, help='ONNX model path')
    parser.add_argument('--output', type=str, default=None, help='Output RKNN model path')
    parser.add_argument('--target', type=str, default='rk3588', 
                        help='Target platform (rk3562, rk3566, rk3568, rk3576, rk3588, rv1126b)')
    parser.add_argument('--quantize', action='store_true', help='Enable INT8 quantization')
    args = parser.parse_args()

    output_path = convert_onnx_to_rknn(
        onnx_path=args.onnx,
        platform=args.target,
        do_quant=args.quantize,
        output_path=args.output
    )
    
    if output_path is None:
        sys.exit(1)
