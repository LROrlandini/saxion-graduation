import 'dart:typed_data';
import 'dart:convert';
import 'package:usb_serial/usb_serial.dart';
import 'dart:io';

const matrixHeight = 12;
const matrixWidth = 12;
const maxFrames = 4;
var adcStatus = false;
var frameCount = 0;
var frames = [
  LedMatrix(matrixHeight, matrixWidth),
  LedMatrix(matrixHeight, matrixWidth),
  LedMatrix(matrixHeight, matrixWidth),
  LedMatrix(matrixHeight, matrixWidth)
];

class LedMatrix {
  int _height;
  int _width;
  List _matrix;

  LedMatrix(int height, int width) {
    _height = height;
    _width = width;
    _matrix = [];
    for (var row = 0; row < _height; row++) {
      List pixelRow = [];
      for (var col = 0; col < _width; col++) {
        pixelRow.add(Pixel(0, 0));
      }
      _matrix.add(pixelRow);
    }
  }

  toBytesRow(int row) {
    String byteArray = '';
    for (var col = 0; col < 12; col++) {
      byteArray += _matrix[row][col];
    }
    return byteArray;
  }

  Pixel getMatrix(int row, int col) {
    return _matrix[row][col];
  }

  void setMatrix(int col, int row, int green, int red) {
    _matrix[col][row].green = green;
    _matrix[col][row].red = red;
  }
}

class Pixel {
  int red = 0;
  int green = 0;

  Pixel(red, green) {
    red = red;
    green = green;
  }

  toByte() {
    return ((green << 4) & 0xF0) | (red & 0x0F);
  }
}

List<int> makePicMsg(String command) {
  var picMsg = <int>[];
  var commandBytes = utf8.encode(command += '\r');
  var cBytes = Uint8List.fromList(commandBytes);
  picMsg.addAll(cBytes);
  return picMsg;
}

void updateLeds(UsbPort port, LedMatrix ledMatrix) {
  String command = 'Set';
  port.write(Uint8List.fromList(makePicMsg(command)));
  for (var row = 0; row < 12; row++) {
    for (var col = 0; col < 12; col++) {
      port.write(Uint8List.fromList([ledMatrix.getMatrix(row, col).toByte()]));
    }

    sleep(const Duration(milliseconds: 1));
  }
}

void clearLeds() {
  for (var i = 0; i < maxFrames; i++) {
    for (var row = 0; row < frames[i]._height; row++) {
      for (var col = 0; col < frames[i]._width; col++) {
        frames[i].setMatrix(row, col, 0, 0);
      }
    }
  }
}

void fillMatrix(int green, int red) {
  for (var i = 0; i < maxFrames; i++) {
    for (var row = 0; row < frames[i]._height; row++) {
      for (var col = 0; col < frames[i]._width; col++) {
        frames[i].setMatrix(col, row, green, red);
      }
    }
  }
}

void toggleADC(UsbPort port) {
  String command = 'Get';
  port.write(Uint8List.fromList(makePicMsg(command)));
  command = 'Adc';
  port.write(Uint8List.fromList(makePicMsg(command)));
  adcStatus = !adcStatus;
}
