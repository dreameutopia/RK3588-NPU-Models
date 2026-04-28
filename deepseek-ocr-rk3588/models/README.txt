This directory contains the model files required for DeepSeek-OCR inference.

Required files:
- deepseekocr_vision_rk3588.rknn    (Vision encoder model)
- deepseekocr_w4a16_rk3588.rkllm    (LLM decoder model)

You can export these models using the scripts in rknn-llm/examples/multimodal_model_demo/

Export Vision model:
```bash
cd ../rknn-llm/examples/multimodal_model_demo
python export/export_vision.py --path=/path/to/DeepSeek-OCR --model_name=deepseekocr --height=448 --width=448
python export/export_vision_rknn.py --path=./onnx/deepseekocr_vision.onnx --model_name=deepseekocr --target-platform rk3588
```

Export LLM model:
```bash
cd ../rknn-llm/examples/multimodal_model_demo
python export/export_rkllm.py --path=/path/to/DeepSeek-OCR --target-platform rk3588 --num_npu_core 3 --quantized_dtype w4a16
```
