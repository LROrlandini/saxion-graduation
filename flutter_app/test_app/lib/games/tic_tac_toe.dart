import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

import '../utilities/board_handler.dart';
import '../utilities/helper_functions.dart';
import '../utilities/neural_net.dart';

UsbPort boardPort;

/*------------------------------------------------------------------------------
Class TicTacToe
------------------------------------------------------------------------------*/
class TicTacToe extends StatefulWidget {
  const TicTacToe({Key key}) : super(key: key);

  @override
  _TicTacToeState createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe> {
  /*----------------------------------------------------------------------------
  Member Variables
  ----------------------------------------------------------------------------*/
  var _scoreGreen = 0, _scoreRed = 0;
  var _greenTurn = true;
  var _boardStatus = "Disconnected";
  int _boardId;
  final _gameGrid = List<String>.filled(9, '');

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
      boardPort = null;
      return false;
    }
    _boardId = device.deviceId;

    await boardPort.setDTR(true);
    await boardPort.setRTS(true);
    await boardPort.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        boardPort.inputStream, Uint8List.fromList([10]));

    loadModelAndScaler(1);
    toggleADC(boardPort);
    await Future.delayed(const Duration(seconds: 1));

    _subscription = _transaction.stream.listen((String serialString) {
      setState(() {
        //writeConsole(serialString);
        if (adcStatus) {
          var startPosition = serialString.indexOf("LM");
          if (startPosition > -1) {
            startPosition += 4;
            var readings = serialString.substring(startPosition);
            var prediction = predict(parseAndScale(readings), 10);
            if (prediction != 0) {
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
      _scoreGreen = 0;
      _scoreRed = 0;
      _greenTurn = true;
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
  /* Stores serial messages receive to file in mobile phone
  
  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/console.txt');
  }

  Future<File> writeConsole(String serialMessage) async {
    final file = await _localFile;
    return file.writeAsString(serialMessage, mode: FileMode.append);
  }

  */

  void _clearBoard() {
    clearLeds();
    setState(() {
      for (var i = 0; i < _gameGrid.length; i++) {
        _gameGrid[i] = '';
      }
    });
  }

  void _placeCross(LedMatrix ledMatrix, int pos, green) {
    var col = (pos) * 4 % 12;
    var row = ((pos) * 4 ~/ 12);
    row *= 4;

    var valGreen = 0, valRed = 0;
    if (green == true) {
      valGreen = 5;
    } else if (green == false) {
      valRed = 5;
    }

    for (var i = 0; i < 4; i++) {
      if (i == 0 || i == 3) {
        ledMatrix.setMatrix(col + i, row + 0, valGreen, valRed);
        ledMatrix.setMatrix(col + i, row + 3, valGreen, valRed);
      } else {
        ledMatrix.setMatrix(col + i, row + 1, valGreen, valRed);
        ledMatrix.setMatrix(col + i, row + 2, valGreen, valRed);
      }
    }
  }

  void _tapped(int quadrant) {
    setState(() {
      quadrant--;
      var turn = 'r';
      if (_greenTurn) turn = 'g';
      if (_gameGrid[quadrant] == '') {
        _gameGrid[quadrant] = turn;
        for (var i = 0; i < maxFrames; i++) {
          _placeCross(frames[i], quadrant, _greenTurn);
        }
        var rounds = _gameGrid
            .map((e) => e == '' ? 1 : 0)
            .reduce((value, e) => value + e);
        if (rounds < 5) {
          _checkIfWin(rounds);
        }
        _greenTurn = !_greenTurn;
      }
    });
  }

  void _checkIfWin(int rounds) {
    // Check rows
    for (int i = 0; i < 9; i += 3) {
      if (_gameGrid[i] != '') {
        if ((_gameGrid[i] == _gameGrid[i + 1]) &&
            (_gameGrid[i] == _gameGrid[i + 2])) {
          _showAlertDialog('Winner', _gameGrid[i]);
          return;
        }
      }
    }
    // Check columns
    for (int i = 0; i < 3; i++) {
      if (_gameGrid[i] != '') {
        if ((_gameGrid[i] == _gameGrid[i + 3]) &&
            (_gameGrid[i] == _gameGrid[i + 6])) {
          _showAlertDialog('Winner', _gameGrid[i]);
          return;
        }
      }
    }
    // Check diagonals
    if (_gameGrid[4] != '') {
      if (((_gameGrid[4] == _gameGrid[0]) && (_gameGrid[4] == _gameGrid[8])) ||
          ((_gameGrid[4] == _gameGrid[2]) && (_gameGrid[4] == _gameGrid[6]))) {
        _showAlertDialog('Winner', _gameGrid[4]);
        return;
      }
    }

    if (rounds == 0) {
      _showAlertDialog('Draw', '');
    }
  }

  void _showAlertDialog(String title, String winner) {
    showAlertDialog(
        context: context,
        title: title,
        content: winner == ''
            ? 'Draw'
            : 'The winner is ${winner == 'g' ? 'GREEN' : 'RED'}',
        defaultActionText: 'OK',
        onOkPressed: () {
          _clearBoard();
          Navigator.of(context).pop();
        });

    if (winner == 'g') {
      _scoreGreen += 1;
    } else if (winner == 'r') {
      _scoreRed += 1;
    }
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
          'Tic Tac Toe',
          style: kCustomText(
              fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          _buildPointsTable(),
          _buildGrid(),
          _buildTurn(),
          _buildUsb(),
        ],
      ),
    );
  }

  Widget _buildPointsTable() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Green',
              style: kCustomText(
                  fontSize: 20.0,
                  color: Colors.green,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              _scoreGreen.toString(),
              style: kCustomText(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Red',
              style: kCustomText(
                  fontSize: 20.0,
                  color: Colors.red,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              _scoreRed.toString(),
              style: kCustomText(
                  color: Colors.red,
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1.2,
            crossAxisCount: 3,
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
                          _gameGrid[index] == 'r' ? Colors.red : Colors.green,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget _buildTurn() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        _greenTurn ? 'TURN OF GREEN' : 'TURN OF RED',
        style: _greenTurn
            ? kCustomText(color: Colors.green, fontWeight: FontWeight.w800)
            : kCustomText(color: Colors.red, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 30),
    ]);
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
} // Class TicTacToe
