from tensorflow_lite_support.metadata.python.metadata import metadata_schema_py_generated as _metadata_fb
from tensorflow_lite_support.metadata.python.metadata_displayer import MetadataDisplayer

# モデルのパスを指定
model_path = "assets/lite-model_imagenet_mobilenet_v3_small_100_224_classification_5_metadata_1.tflite"

# メタデータの取得
displayer = MetadataDisplayer.with_model_file(model_path)
metadata_json_str = displayer.get_metadata_json()

print(metadata_json_str)
