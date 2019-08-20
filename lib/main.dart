import 'package:flutter/material.dart';
import 'dart:math';

const guessTextStyle = TextStyle(color: Colors.red, fontSize: 30);
const hexLabelTextStyle = TextStyle(color: Colors.black38, fontSize: 15);
const hexValueTextStyle = TextStyle(color: Colors.black87, fontSize: 150);
const scoreLabelTextStyle = TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold);
const scoreValueTextStyle = TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold);

void main() => runApp(HexFlash());

class HexFlash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "HexFlash",
      theme: ThemeData(
        fontFamily: '.SF UI Display',
        primarySwatch: Colors.red,
      ),
      home: BasePage()
    );
  }
}

class BasePage extends StatefulWidget {
  final String title = "HexFlash: The Mobile Experience";

  @override
  GameState createState() => GameState();
}

class GameState extends State<BasePage> {
  int _corrects = 0;
  int _incorrects = 0;
  int _time = DateTime.now().millisecondsSinceEpoch;
  List<int> _times = [];
  int _value = -1;

  Random _gen = new Random(DateTime.now().millisecondsSinceEpoch);

  double get _averageTime => (_times.fold(0, (a, c) => a + c) / _times.length) / 1000;
  void _incrementCorrects() => setState(() => ++_corrects);
  void _incrementIncorrects() => setState(() => ++_incorrects);
  void _newTime() => setState(() => _time = DateTime.now().millisecondsSinceEpoch);
  void _newValue() => setState(() => _value = _gen.nextInt(255));
  void _recordTime() => setState(() => _times.add(DateTime.now().millisecondsSinceEpoch - _time));

  void _handleGuess(int guess) {
    if (guess == _value) {
      _incrementCorrects();
    } else {
      _incrementIncorrects();
    }
    _recordTime();
    _newTime();
    _newValue();
  }

  List<Widget> _guessButtonList(BuildContext context) {
    List<Widget> list = [];
    var genNumber = (int index) => _gen.nextBool() ? _value - index : _value + index;
    for (var value in [_value, genNumber(1), genNumber(2)]) {
      list.add(Builder(
        builder: (context) => GuessButton(context: context, handler: _handleGuess, value: value)
      ));
    }
    list.shuffle();
    return list;
  }

  // TODO: Class or at least memoize the table...
  void _showDialog() {
    var cellWrap = (String value) => Padding(
      padding: EdgeInsets.all(5),
      child: Center(child: Text(value)),
    );
    List<TableRow> rows = List<TableRow>.generate(16, (i) {
      return TableRow(
        children: [
          cellWrap(i.toRadixString(16).toString()),
          cellWrap((i * 16).toString()),
          cellWrap(i.toString()),
        ]
      );
    });
    Table table = Table(
      children: rows,
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
          title: Center(child: Text("PAUSED")),
          content: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text("You will see a new number after you resume, you little cheater.")
              ),
              Text("Maybe take this time to reflect or review this handy hex table:"),
              Divider(),
              table,
              Divider(),
              Center(child: RaisedButton(
                color: Colors.red,
                child: new Text("Resume"),
                onPressed: () {
                  _newTime();
                  _newValue();
                  Navigator.of(context).pop();
                },
                splashColor: Colors.white,
                textColor: Colors.white,
              )),
            ]
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Have this happen in the constructor
    if (_value == -1) { _newValue(); }

    return Scaffold(
      backgroundColor: Colors.red,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: <Widget> [
          ScoreboardRow(average: _averageTime, correct: _corrects, incorrect: _incorrects),
          Row(children: [Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: HexCard(value: _value),
            )
          )]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _guessButtonList(context)
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding (
                padding: EdgeInsets.symmetric(vertical: 130),
                child: IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.pause),
                  onPressed: _showDialog,
                  splashColor: Colors.white,
                )
              )
            ]
          ),
        ],
      ),
    );
  }
}

class GuessButton extends StatelessWidget {
  GuessButton({Key key, BuildContext context, Function handler, int value}) : super(key: key) {
    _context = context;
    _handler = handler;
    _value = value;
  }

  BuildContext _context;
  Function _handler;
  int _value;
  
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Colors.white,
      elevation: 5.0,
      onPressed: () {
        _handler(_value);
      },
      padding: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
      splashColor: Colors.red,
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          _value.toString(),
          style: guessTextStyle
        ),
      ),
    );
  }
}

class HexCard extends StatelessWidget {
  HexCard({Key key, this.value}) : super(key: key);

  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: <Widget> [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Text(
              "What is the decimal value of?",
              style: hexLabelTextStyle
            )
          ),
          Text(
            value.toRadixString(16).toString(),
            style: hexValueTextStyle
          ),
        ]
      )
    );
  }
}

class ScoreboardRow extends StatelessWidget {
  ScoreboardRow({Key key, this.average, this.correct, this.incorrect}) : super(key: key);

  final double average;
  final int correct;
  final int incorrect;

  @override
  Widget build(BuildContext context) {
    var avg = average.isNaN ? "0" : average.toStringAsFixed(2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget> [
        Column(
          children: [
            Text(correct.toString(), style: scoreValueTextStyle),
            Text("correct", style: scoreLabelTextStyle)
          ]
        ),
        Column(
          children: [
            Text(avg, style: scoreValueTextStyle),
            Text("avg. time", style: scoreLabelTextStyle)
          ]
        ),

        Column(
          children: [
            Text(incorrect.toString(), style: scoreValueTextStyle),
            Text("incorrect", style: scoreLabelTextStyle)
          ]
        ),
      ]
    );
  }
}
