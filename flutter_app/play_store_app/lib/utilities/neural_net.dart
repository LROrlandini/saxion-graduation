import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

var scalerMin = List.filled(144, 0.0);
var scalerMax = List.filled(144, 0.0);
Interpreter neuralNet;

void loadModelAndScaler(int accuracy) async {
  String minMaxValues;

  if (accuracy == 1) {
    neuralNet = await Interpreter.fromAsset('nn_quad.tflite');
    minMaxValues = await rootBundle.loadString('assets/min_max_quad.txt');
  } else if (accuracy == 2) {
    neuralNet = await Interpreter.fromAsset('nn_square.tflite');
    minMaxValues = await rootBundle.loadString('assets/min_max_square.txt');
  } else if (accuracy == 3) {
    neuralNet = await Interpreter.fromAsset('nn_led.tflite');
    minMaxValues = await rootBundle.loadString('assets/min_max_led.txt');
  }
  var minMax = minMaxValues.split('\n');
  for (var i = 0; i < 144; i++) {
    scalerMin[i] = double.parse(minMax[i]);
  }
  for (var i = 144; i < 288; i++) {
    scalerMax[i - 144] = double.parse(minMax[i]);
  }
}

void clearModelAndScaler() {
  scalerMin = null;
  scalerMax = null;
  scalerMin = List.filled(144, 0.0);
  scalerMax = List.filled(144, 0.0);
  neuralNet = null;
}

List<double> minMaxScaler(List<String> adcValues) {
  var scaledMatrix = List<double>.filled(144, 0.0);

  for (var i = 0; i < 144; i++) {
    scaledMatrix[i] = (double.parse(adcValues[i]) - scalerMin[i]) /
        (scalerMax[i] - scalerMin[i]);
  }
  return scaledMatrix;
}

List<double> parseAndScale(String serialReadings) {
  serialReadings = serialReadings.replaceAll('], [', ',');
  serialReadings = serialReadings.replaceAll('[', '');
  serialReadings = serialReadings.replaceAll(']]', '');

  return minMaxScaler(serialReadings.split(','));
}

int predict(List<double> scaledMatrix, int range) {
  var prediction = 0;
  var maxValue = 0.0;
  var result = List.filled(1, List<double>.filled(range, 0.0));

  neuralNet.run(scaledMatrix, result);

  for (var i = 0; i < result[0].length; i++) {
    if (result[0][i] > maxValue) {
      maxValue = result[0][i];
      if (maxValue > 0.35) {
        prediction = i;
      }
    }
  }
  return prediction;
}
