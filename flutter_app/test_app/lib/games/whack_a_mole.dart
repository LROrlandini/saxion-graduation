import 'dart:async';
import 'dart:math';
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
class WhackAMole extends StatefulWidget {
  const WhackAMole({Key key}) : super(key: key);

  @override
  _WhackAMoleState createState() => _WhackAMoleState();
}

class _WhackAMoleState extends State<WhackAMole> {
  /*----------------------------------------------------------------------------
  Member Variables
  ----------------------------------------------------------------------------*/
  var _level = 1, _hits = 0, _previousTap = 0;
  var _boardStatus = "Disconnected";
  var adcReading = false;
  int _boardId;
  final _random = Random();
  final _currentRound = <int>[];
  final _gameGrid = List<String>.filled(36, '');

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
                      _generateRound();
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

    loadModelAndScaler(2);

    _subscription = _transaction.stream.listen((String serialString) {
      setState(() {
        if (adcReading) {
          var startPosition = serialString.indexOf("LM");
          if (startPosition > -1) {
            startPosition += 4;
            var readings = serialString.substring(startPosition);
            var prediction = predict(parseAndScale(readings), 37);
            if ((prediction != 0) && (prediction != _previousTap)) {
              _previousTap = prediction;
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
      _level = 1;
      _hits = 0;
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
      for (var i = 0; i < 36; i++) {
        _gameGrid[i] = '';
      }
      _currentRound.clear();
    });
  }

  void _generateRound() {
    setState(() async {
      _previousTap = 0;
      for (var i = 0; i < _level; i++) {
        var number = _random.nextInt(36);
        if (_currentRound.contains(number)) {
          i--;
        } else {
          _currentRound.add(number);
          _gameGrid[number] = 'm';
        }
      }
      for (var i = 0; i < _level; i++) {
        for (var j = 0; j < maxFrames; j++) {
          _placeSquare(frames[j], _currentRound[i], false);
        }
      }
      await Future.delayed(const Duration(seconds: 3));
      clearLeds();
      toggleADC(boardPort);
      await Future.delayed(const Duration(seconds: 1));
      adcReading = true;
    });
  }

  void _placeSquare(LedMatrix ledMatrix, int pos, playerTurn) {
    var col = (pos) * 2 % 12;
    var row = ((pos) * 2 ~/ 12) * 2;

    var valGreen = 0, valRed = 0;
    if (playerTurn == true) {
      valGreen = 5;
    } else if (playerTurn == false) {
      valRed = 5;
    }

    ledMatrix.setMatrix(col + 0, row + 0, valGreen, valRed);
    ledMatrix.setMatrix(col + 0, row + 1, valGreen, valRed);
    ledMatrix.setMatrix(col + 1, row + 0, valGreen, valRed);
    ledMatrix.setMatrix(col + 1, row + 1, valGreen, valRed);
  }

  void _tapped(int square) {
    setState(() {
      square--;
      _hits++;
      if (_gameGrid[square] == 'm') {
        _gameGrid[square] = '*';
      } else if (_gameGrid[square] == '') {
        _gameGrid[square] = '-';
      }
      for (var i = 0; i < maxFrames; i++) {
        _placeSquare(frames[i], square, true);
      }
      if (_hits == _level) {
        adcReading = false;
        toggleADC(boardPort);
        _hits = 0;
        _checkIfCorrect();
      }
    });
  }

  void _checkIfCorrect() async {
    var misses = 0;
    for (int i = 0; i < 36; i++) {
      if (_gameGrid[i] == '-') {
        misses++;
      }
    }
    misses > 0 ? fillMatrix(0, 5) : fillMatrix(5, 0);
    await Future.delayed(const Duration(seconds: 1));
    _showAlertDialog(misses == 0 ? 'Great Success!' : 'Massive Fail!', misses);
  }

  void _showAlertDialog(String title, int misses) {
    showAlertDialog(
        context: context,
        title: title,
        content: misses > 0
            ? 'You have missed $misses ${misses == 1 ? 'mole!' : 'moles!'}'
            : 'All moles have been hit!',
        defaultActionText: 'OK',
        onOkPressed: () {
          _generateRound();
          Navigator.of(context).pop();
        });
    if (misses == 0) {
      _level++;
      if (_level > 9) {
        _level = 1;
      }
    } else {
      _level = 1;
    }
    _clearBoard();
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
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              _clearBoard();
            },
          )
        ],
        title: Text(
          'Whack A Mole',
          style: kCustomText(
              fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          _buildLevelTable(),
          _buildGrid(),
          _buildUsb(),
        ],
      ),
    );
  }

  Widget _buildLevelTable() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'Level',
          style: kCustomText(
              fontSize: 20.0, color: Colors.green, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          _level.toString(),
          style: kCustomText(
              fontSize: 25.0, color: Colors.green, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15)
      ],
    );
  }

  Widget _buildGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
          itemCount: 36,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1.15,
            crossAxisCount: 6,
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey[700])),
                child: Center(
                  child: Text(
                    _gameGrid[index],
                    style: TextStyle(
                      color:
                          _gameGrid[index] == 'm' ? Colors.red : Colors.green,
                      fontSize: 30,
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
} // Class WhackAMole
