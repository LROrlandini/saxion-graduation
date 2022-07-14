import 'package:flutter/material.dart';

import 'games/tic_tac_toe.dart';
import 'games/whack_a_mole.dart';
import 'games/drawing_board.dart';
import 'utilities/helper_functions.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
              icon: Image.asset("icons/aemics-icon.png"), onPressed: () {})
        ],
        title: Text(
          'Aemics Gadget Board',
          style: kCustomText(
              fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          _appList(),
        ],
      ),
    );
  }

  Widget _appList() {
    return Column(children: [
      /*----------------------------------------------------------------------*/
      const SizedBox(height: 15),
      /*----------------------------------------------------------------------*/
      Row(children: [
        const SizedBox(width: 25),
        Column(children: [
          IconButton(
            iconSize: 50,
            color: Colors.blue,
            icon: const Icon(Icons.grid_3x3_outlined),
            onPressed: _ticTacToe,
          ),
          Text(
            'Tic   Tac   Toe  ',
            style: kCustomText(
                fontSize: 15.0,
                color: Colors.black,
                fontWeight: FontWeight.w800),
          ),
        ]),
        const SizedBox(width: 15),
        Text(
          'Players required: 2\n'
          'The 1st player (green) must choose one of the 9\n'
          'quadrants to start. The 2nd player (red) will follow\n'
          'and rounds will alternate between them going forward.\n'
          'A player must complete a row, column or diagonal with\n'
          'their own colour to win.',
          style: kCustomText(
              fontSize: 10.0, color: Colors.black, fontWeight: FontWeight.w800),
        )
      ]),
      /*----------------------------------------------------------------------*/
      const SizedBox(height: 50),
      /*----------------------------------------------------------------------*/
      Row(children: [
        const SizedBox(width: 25),
        Column(children: [
          IconButton(
            alignment: Alignment.center,
            iconSize: 50,
            color: Colors.blue,
            icon: const Icon(Icons.hardware),
            onPressed: _whackAMole,
          ),
          Text(
            'Whack A Mole ',
            style: kCustomText(
                fontSize: 15.0,
                color: Colors.black,
                fontWeight: FontWeight.w800),
          ),
        ]),
        const SizedBox(width: 15),
        Text(
          'Players required: 1\n'
          'Starting at level 1, the game logic will display the\n'
          'the position of 1 mole for a couple of seconds. The\n'
          'player must then remember where the mole was and tap\n'
          'it. If correct, the game will progress to level 2 where\n'
          '2 moles will appear. Then with level 3 there will be 3\n'
          'moles and so on. The game ends after 9 successful\n'
          'consecutive rounds. A mistake will reset the game.',
          style: kCustomText(
              fontSize: 10.0, color: Colors.black, fontWeight: FontWeight.w800),
        )
      ]),
      /*----------------------------------------------------------------------*/
      const SizedBox(height: 50),
      /*----------------------------------------------------------------------*/
      Row(children: [
        const SizedBox(width: 25),
        Column(children: [
          IconButton(
            iconSize: 50,
            color: Colors.blue,
            icon: const Icon(Icons.draw),
            onPressed: _drawingBoard,
          ),
          Text(
            'Drawing Board',
            style: kCustomText(
                fontSize: 15.0,
                color: Colors.black,
                fontWeight: FontWeight.w800),
          ),
        ]),
        const SizedBox(width: 15),
        Text(
          'Players required: 1\n'
          'This game is a blank board where the player\n'
          'can draw using their fingers.\n'
          'The button at the top will clean the board.\n'
          'Tapping a LED once will switch on green light,\n'
          'twice will switch on red light, thrice will\n'
          'switch on both. An extra click will switch it off.',
          style: kCustomText(
              fontSize: 10.0, color: Colors.black, fontWeight: FontWeight.w800),
        )
      ]),
    ]);
  }

  void _ticTacToe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TicTacToe()),
    );
  }

  void _whackAMole() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WhackAMole()),
    );
  }

  void _drawingBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DrawingBoard()),
    );
  }
}
