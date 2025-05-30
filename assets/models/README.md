# Model Files

This directory is where the TensorFlow Lite model files should be placed.

## Expected Files

- `food_classifier.tflite` - Food classification model

## Model Acquisition

The actual model files are not included in the repository due to size constraints.
You'll need to download or train your own models and place them here.

For development purposes, the app will fall back to Google ML Kit for image classification if the TFLite model is not available. 