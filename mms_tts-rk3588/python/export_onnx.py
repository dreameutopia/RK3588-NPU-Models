#!/usr/bin/env python3
"""
MMS-TTS ONNX Export Script (RKNN Compatible)
Based on rknn_model_zoo/examples/mms_tts

This script exports MMS-TTS model to two separate ONNX files:
- encoder: input_ids, attention_mask -> log_duration, input_padding_mask, prior_means, prior_log_variances
- decoder: attn, output_padding_mask, prior_means, prior_log_variances -> waveform
"""

import os
import sys
import argparse
import numpy as np
import torch
import warnings
warnings.filterwarnings("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=torch.jit.TracerWarning)

RANDN_LIKE_LATENTS_PATH = os.path.join(os.path.dirname(__file__), '..', 'model', 'randn_like_latents.npy')
os.environ['randn_like_latents_path'] = os.path.abspath(RANDN_LIKE_LATENTS_PATH)

def setup_model(model_name):
    from transformers import VitsModel, AutoTokenizer
    model = VitsModel.from_pretrained(model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model.requires_grad_(False)
    model.eval()
    return model, tokenizer


def patch_vits_model():
    """
    Patch VITS model to be RKNN compatible.
    Replace dynamic operators like cumsum, NonZero, etc.
    """
    import torch.nn as nn
    import math
    
    from transformers.models.vits.modeling_vits import (
        _unconstrained_rational_quadratic_spline as original_spline,
        VitsStochasticDurationPredictor
    )
    
    def _unconstrained_rational_quadratic_spline_fixed(
        inputs,
        unnormalized_widths,
        unnormalized_heights,
        unnormalized_derivatives,
        reverse=False,
        tail_bound=5.0,
        min_bin_width=1e-3,
        min_bin_height=1e-3,
        min_derivative=1e-3,
    ):
        inside_interval_mask = (-inputs < tail_bound).float().int() * (-inputs > -tail_bound).float().int()
        outside_interval_mask = 1 - inside_interval_mask

        outside_interval_mask = outside_interval_mask.bool()
        inside_interval_mask = inside_interval_mask.bool()

        outputs = torch.zeros_like(inputs)
        log_abs_det = torch.zeros_like(inputs)
        constant = np.log(np.exp(1 - min_derivative) - 1)

        unnormalized_derivatives = nn.functional.pad(unnormalized_derivatives, pad=(1, 0))
        unnormalized_derivatives[..., 0] = constant
        unnormalized_derivatives[..., -1] = constant

        outputs = torch.add(outputs, outside_interval_mask.float().int() * inputs)

        log_abs_det[outside_interval_mask] = 0.0
        inputs_inside_interval_mask = inside_interval_mask.float().int() * inputs
        unnormalized_widths_inside_interval_mask = inside_interval_mask.float().int()[..., None] * unnormalized_widths
        unnormalized_heights_inside_interval_mask = inside_interval_mask.float().int()[..., None] * unnormalized_heights
        unnormalized_derivatives_inside_interval_mask = inside_interval_mask.float().int()[..., None] * unnormalized_derivatives

        from transformers.models.vits.modeling_vits import _rational_quadratic_spline
        outputs_inside_interval_mask, log_abs_det_inside_interval_mask = _rational_quadratic_spline(
            inputs=inputs_inside_interval_mask.squeeze(),
            unnormalized_widths=unnormalized_widths_inside_interval_mask.squeeze(),
            unnormalized_heights=unnormalized_heights_inside_interval_mask.squeeze(),
            unnormalized_derivatives=unnormalized_derivatives_inside_interval_mask.squeeze(),
            reverse=reverse,
            tail_bound=tail_bound,
            min_bin_width=min_bin_width,
            min_bin_height=min_bin_height,
            min_derivative=min_derivative,
        )

        outputs = torch.add(outputs_inside_interval_mask, inside_interval_mask.float().int() * outputs)
        log_abs_det = torch.add(log_abs_det_inside_interval_mask, inside_interval_mask.float().int() * log_abs_det)
        return outputs, log_abs_det

    import transformers.models.vits.modeling_vits as vits_module
    vits_module._unconstrained_rational_quadratic_spline = _unconstrained_rational_quadratic_spline_fixed


def export_onnx(model, tokenizer, output_dir, max_length=200, language="eng"):
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(os.path.dirname(RANDN_LIKE_LATENTS_PATH), exist_ok=True)
    
    text = "some example text in the English language"
    inputs = tokenizer(text, return_tensors="pt", padding="max_length", max_length=max_length, truncation=True)
    input_ids = inputs['input_ids']
    attention_mask = inputs['attention_mask']
    
    randn_like_latents = torch.randn(input_ids.size(0), 2, input_ids.size(1))
    np.save(RANDN_LIKE_LATENTS_PATH, randn_like_latents)
    
    log_duration, input_padding_mask, prior_means, prior_log_variances = model(input_ids, attention_mask)

    encoder_path = os.path.join(output_dir, f"mms_tts_{language}_encoder_{max_length}.onnx")
    decoder_path = os.path.join(output_dir, f"mms_tts_{language}_decoder_{max_length}.onnx")
    
    print(f"Exporting encoder to {encoder_path}...")
    torch.onnx.export( 
        model,
        (input_ids, attention_mask),
        encoder_path,
        do_constant_folding=True,
        export_params=True,
        input_names=['input_ids', 'attention_mask'],
        output_names=['log_duration', 'input_padding_mask', 'prior_means', 'prior_log_variances'],
        opset_version=12)
    print(f"Encoder saved to: {encoder_path}")

    speaking_rate = 1.0
    length_scale = 1.0 / speaking_rate
    duration = torch.ceil(torch.exp(log_duration) * input_padding_mask * length_scale)
    predicted_lengths = torch.clamp_min(torch.sum(duration, [1, 2]), 1).long()
    predicted_lengths_max = max_length * 2
    indices = torch.arange(predicted_lengths_max, dtype=predicted_lengths.dtype, device=predicted_lengths.device)
    output_padding_mask = indices.unsqueeze(0) < predicted_lengths.unsqueeze(1)
    output_padding_mask = output_padding_mask.unsqueeze(1).to(input_padding_mask.dtype)
    attn_mask = torch.unsqueeze(input_padding_mask, 2) * torch.unsqueeze(output_padding_mask, -1)
    batch_size, _, output_length, input_length = attn_mask.shape
    cum_duration = torch.cumsum(duration, -1).view(batch_size * input_length, 1)
    indices = torch.arange(output_length, dtype=duration.dtype, device=duration.device)
    valid_indices = indices.unsqueeze(0) < cum_duration
    valid_indices = valid_indices.to(attn_mask.dtype).view(batch_size, input_length, output_length)
    padded_indices = valid_indices - nn.functional.pad(valid_indices, [0, 0, 1, 0, 0, 0])[:, :-1]
    attn = padded_indices.unsqueeze(1).transpose(2, 3) * attn_mask
    
    print(f"Exporting decoder to {decoder_path}...")
    torch.onnx.export(
        model,
        (attn, output_padding_mask, prior_means, prior_log_variances),
        decoder_path,
        do_constant_folding=True,
        export_params=True,
        input_names=['attn', 'output_padding_mask', 'prior_means', 'prior_log_variances'],
        output_names=['waveform'],
        opset_version=12)
    print(f"Decoder saved to: {decoder_path}")
    
    print(f"\nExport completed!")
    print(f"Encoder: {encoder_path}")
    print(f"Decoder: {decoder_path}")
    print(f"Random latents: {RANDN_LIKE_LATENTS_PATH}")
    
    return encoder_path, decoder_path


def main():
    parser = argparse.ArgumentParser(description='Export MMS-TTS ONNX model for RKNN')
    parser.add_argument('--model_name', type=str, default='facebook/mms-tts-eng',
                        help='HuggingFace model name')
    parser.add_argument('--language', type=str, default='eng',
                        help='Language code')
    parser.add_argument('--output_dir', type=str, default='onnx',
                        help='Output directory for ONNX models')
    parser.add_argument('--max_length', type=int, default=200,
                        help='Max input length (default: 200)')
    args = parser.parse_args()

    print("=" * 60)
    print("MMS-TTS ONNX Export (RKNN Compatible)")
    print("=" * 60)
    print(f"Model: {args.model_name}")
    print(f"Language: {args.language}")
    print(f"Max Length: {args.max_length}")
    print(f"Output: {args.output_dir}")
    print("=" * 60)
    print()

    print("Patching VITS model for RKNN compatibility...")
    patch_vits_model()
    
    print("Loading model...")
    model, tokenizer = setup_model(args.model_name)
    
    print("Exporting ONNX models...")
    export_onnx(model, tokenizer, args.output_dir, args.max_length, args.language)
    
    print("\nNext steps:")
    print("1. Convert to RKNN:")
    print(f"   python3 python/convert_rknn.py --encoder onnx/mms_tts_{args.language}_encoder_{args.max_length}.onnx --decoder onnx/mms_tts_{args.language}_decoder_{args.max_length}.onnx")
    print("2. Run inference:")
    print(f"   python3 python/mms_tts.py --encoder model/mms_tts_{args.language}_encoder.rknn --decoder model/mms_tts_{args.language}_decoder.rknn")


if __name__ == '__main__':
    main()
