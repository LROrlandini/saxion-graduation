import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

import '../utilities/board_handler.dart';
import '../utilities/helper_functions.dart';
import '../utilities/neural_net.dart';

UsbPort boardPort;

/*------------------------------------------------------------------------------
Class TicTacToe
------------------------------------------------------------------------------*/
class DrawingBoard extends StatefulWidget {
  const DrawingBoard({Key key}) : super(key: key);

  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  /*----------------------------------------------------------------------------
  Member Variables
  ----------------------------------------------------------------------------*/
  var _boardStatus = "Disconnected";
  var adcReading = false;
  int _boardId;
  final _gameGrid = List<int>.filled(144, 0);

  List<Widget> _ports = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;

  var _tmr = Timer.periodic(const Duration(milliseconds: 250), (Timer timer) {
    updateLeds(boardPort, frames[frameCount]);
    frameCount++;
    if (frameCount == 4) frameCount = 0;
  });

  /*----------------------------------------------------------------------------
  Connection Handlers
  ----------------------------------------------------------------------------*/
  @override
  void initState() {
    super.initState();
    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });
    _getPorts();
  }

  @override
  void dispose() async {
    if (_boardStatus == "Connected") {
      await _disconnect();
    }
    if (_tmr != null) {
      _tmr.cancel();
      _tmr = null;
    }
    if (super != null) {
      super.dispose();
    }
  }

  void _getPorts() async {
    _ports = [];
    var devices = await UsbSerial.listDevices();

    for (var dev in devices) {
      _ports.add(ListTile(
          leading: const Icon(Icons.usb),
          title: Text(dev.productName),
          trailing: ElevatedButton(
            child: Text(_boardId == dev.deviceId ? "Disconnect" : "Connect"),
            onPressed: () {
              _boardId == dev.deviceId
                  ? _disconnect().then((res) {
                      _getPorts();
                    })
                  : _connect(dev).then((res) {
                      _getPorts();
                    });
            },
          )));
    }
    setState(() {});
  }

  _connect(UsbDevice device) async {
    boardPort = await device.create();
    if (!await boardPort.open()) {
      setState(() {
        _boardStatus = "Failed to open port";
      });
      return false;
    }
    _boardId = device.deviceId;

    await boardPort.setDTR(false);
    await boardPort.setRTS(false);
    await boardPort.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        boardPort.inputStream, Uint8List.fromList([10]));

    loadModelAndScaler(3);
    toggleADC(boardPort);
    await Future.delayed(const Duration(seconds: 1));
    adcReading = true;

    _subscription = _transaction.stream.listen((String serialString) {
      setState(() {
        if (adcReading) {
          int startPosition = serialString.indexOf("LM");
          if (startPosition > -1) {
            startPosition += 4;
            var readings = serialString.substring(startPosition);
            var prediction = predict(parseAndScale(readings), 145);
            if (prediction != 0) {
              adcReading = false;
              _tapped(prediction);
            }
          }
        }
      });
    });

    setState(() {
      _boardStatus = "Connected";
    });

    return true;
  }

  _disconnect() async {
    clearModelAndScaler();
    _clearBoard();
    if (adcStatus) {
      toggleADC(boardPort);
    }
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _boardStatus = "Disconnected";
    });

    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }
    if (boardPort != null) {
      boardPort.close();
      boardPort = null;
    }

    _boardId = null;

    return true;
  }

  /*----------------------------------------------------------------------------
  Gameplay Functions
  ----------------------------------------------------------------------------*/
  void _clearBoard() {
    clearLeds();
    setState(() {
      for (var i = 0; i < 144; i++) {
        _gameGrid[i] = 0;
      }
    });
  }

  void _view() async {
    toggleADC(boardPort);
    await Future.delayed(const Duration(seconds: 1));
    adcReading = !adcReading;
  }

  void _placeLed(LedMatrix ledMatrix, int pos, int colour) {
    var col = (pos) % 12;
    var row = ((pos) ~/ 12);

    var valGreen = 0, valRed = 0;

    if (colour == 1) {
      valGreen = 5;
    } else if (colour == 2) {
      valRed = 5;
    } else if (colour == 3) {
      valGreen = 5;
      valRed = 5;
    }

    ledMatrix.setMatrix(col, row, valGreen, valRed);
  }

  void _tapped(int led) async {
    setState(() {
      led--;
      if (_gameGrid[led] == 0) {
        _gameGrid[led] = 1;
      } else if (_gameGrid[led] == 1) {
        _gameGrid[led] = 2;
      } else if (_gameGrid[led] == 2) {
        _gameGrid[led] = 3;
      } else {
        _gameGrid[led] = 0;
      }
      for (var i = 0; i < maxFrames; i++) {
        _placeLed(frames[i], led, _gameGrid[led]);
      }
    });
    await Future.delayed(const Duration(milliseconds: 500));
    adcReading = true;
  }

  /*----------------------------------------------------------------------------
  Widgets
  ----------------------------------------------------------------------------*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera_front_outlined),
            onPressed: () {
              _view();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              _clearBoard();
            },
          )
        ],
        title: Text(
          'Drawing Board',
          style: kCustomText(
              fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          _buildGrid(),
          _buildUsb(),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
          itemCount: 144,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1.15,
            crossAxisCount: 12,
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey[700])),
                child: Center(
                  child: Text(
                    _gameGrid[index].toString(),
                    style: TextStyle(
                      color: _gameGrid[index] == 0
                          ? Colors.blue[50]
                          : Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget _buildUsb() {
    return Expanded(
      child: Column(children: <Widget>[
        Text(_ports.isNotEmpty ? "Device available" : "No devices available",
            style: kCustomText(fontSize: 15.0, fontWeight: FontWeight.w800)),
        Text(
          "$_boardStatus\n",
          style: kCustomText(
              fontSize: 15.0,
              fontWeight: FontWeight.w800,
              color: _boardStatus == "Connected" ? Colors.green : Colors.red),
        ),
        ..._ports,
      ]),
    );
  }
} // Class DrawingBoard
