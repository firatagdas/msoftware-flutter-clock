// Copyright 2020 by Merlin Jentsch, Klaudia Jentsch and Michael Jentsch.
// Made with <3 in Herne, Germany
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
// import 'package:screen/screen.dart';

enum _Element { background, blockBackground, text, blockAlpha }

final _lightTheme = {
  _Element.background: Colors.grey[100],
  _Element.blockBackground: Colors.grey[350],
  _Element.text: Colors.grey[400],
  _Element.blockAlpha: 0.3,
};

final _darkTheme = {
  _Element.background: Colors.grey[850],
  _Element.blockBackground: Colors.grey[800],
  _Element.text: Colors.grey[700],
  _Element.blockAlpha: 0.5,
};

// Size of the tetris grid - Tried also with 40x24 but I don't like it
const int tetrisRows = 50;
const int tetrisCols = 30;

// Needed to get tetris animation data
const blx = 0; // x
const bly = 1; // y
const blr = 2; // rotation
const blt = 3; // block type
const blc = 4; // color

/* Constants for am and pm / 12 hour format only */
const am = 1;
const pm = 2;

/* Const for tetrisNumberAnimationData */
const animationsteps = 1;
const blockcolors = 0;
/*
 * Set the color of the dots between hour and min
 */
const int dotColor = 9;

/*
 * Hide the trailing 0 if hour is < 10
 */
const bool hideTrailingHourZero = true;

/*
 * Show white/black dor for am/pm
 */
const bool showAmPm = false;

/*
 * Show weather conditions on screen
 */
const bool showWeather = true;

/*
 * Tetris animation step duration for animation of blocks
 */
const int tetrisAnimationSpeed = 100;

/*
 * Set keep screen on (Only for testing
 */
// const bool keepScreenOn = true;

/// I can even do better than this, but there is no time left! :-)
class TetrisClock extends StatefulWidget {
  const TetrisClock(this.model);
  final ClockModel model;

  @override
  _TetrisClockState createState() => _TetrisClockState();
}

class _TetrisClockState extends State<TetrisClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  bool showSplashScreen = true;
  bool showSplashScreenOffAnimation = false;
  int splashScreenOffAnimationCounter = 0;

  int lh1 = -1;
  int lh2 = -1;
  int lm1 = -1;
  int lm2 = -1;

  /* last digit value */
  List lastValue = new List.generate(4, (_) => -1);

  /* The grid is used to draw the squares on screen */
  List tetrisGrid =
      List.generate(tetrisRows, (_) => List.generate(tetrisCols, (_) => 0));

  /* Animation data for every block */
  List tetrisNumbers = List.generate(4, (_) => null);
  List lastTetrisNumbers = List.generate(4, (_) => null);

  var themeColors;

  WeatherCondition weather;
  WeatherCondition lastWeather;
  WeatherCondition outWeather;

  /* Weather animation constants */
  int weatherOffset = 0;
  int maxWeatherOffset = -24;
  int weatherAnimationCounter = 0;

  var weatherSun;
  var weatherCloudy;
  var weatherRainy;
  var weatherThunderstorm;
  var weatherSnowy;
  var weatherFoggy;
  var weatherWindy;

  var tetrisSplashScreen;
  var tetrisBlocks;

  var tetrisNumberAnimationData;

  /*
   * Color constants
  */
  static const int empty = 0;
  static const int black = 1;
  static const int blue = 2;
  static const int green = 3;
  static const int purple = 4;
  static const int red = 5;
  static const int orange = 6;
  static const int yellow = 7;
  static const int pink = 8;
  static const int white = 9;

  static Paint blackPaint1 = Paint()..color = new Color(0xff1b1b1b);
  static Paint blackPaint2 = Paint()..color = new Color(0xFF373737);

  static Paint bluePaint1 = Paint()..color = new Color(0xFF003c8f);
  static Paint bluePaint2 = Paint()..color = new Color(0xFF005cb2);

  static Paint greenPaint1 = Paint()..color = new Color(0xFF1b5e20);
  static Paint greenPaint2 = Paint()..color = new Color(0xFF388e3c);

  static Paint purplePaint1 = Paint()..color = new Color(0xFF4a0072);
  static Paint purplePaint2 = Paint()..color = new Color(0xFF9c27b0);

  static Paint redPaint1 = Paint()..color = new Color(0xFF8e0000);
  static Paint redPaint2 = Paint()..color = new Color(0xFFc62828);

  static Paint orangePaint1 = Paint()..color = new Color(0xFFb53d00);
  static Paint orangePaint2 = Paint()..color = new Color(0xFFe65100);

  static Paint yellowPaint1 = Paint()..color = new Color(0xFFf57f17);
  static Paint yellowPaint2 = Paint()..color = new Color(0xFFf9a825);

  static Paint pinkPaint1 = Paint()..color = new Color(0xFFc2185b);
  static Paint pinkPaint2 = Paint()..color = new Color(0xFFe35183);

  static Paint whitePaint1 = Paint()..color = new Color(0xFFbcbcbc);
  static Paint whitePaint2 = Paint()..color = new Color(0xFFeeeeee);

  static Paint greyPaint1 = Paint()..color = new Color(0xFF707070);
  static Paint greyPaint2 = Paint()..color = new Color(0xFFbdbdbd);

  List tetrisPaint = [
    [null, null],
    [blackPaint1, blackPaint2],
    [bluePaint1, bluePaint2],
    [greenPaint1, greenPaint2],
    [purplePaint1, purplePaint2],
    [redPaint1, redPaint2],
    [orangePaint1, orangePaint2],
    [yellowPaint1, yellowPaint2],
    [pinkPaint1, pinkPaint2],
    [whitePaint1, whitePaint2],
    [greyPaint1, greyPaint2],
  ];

  @override
  void initState() {
    super.initState();
    initTetrisData().then((result) {
      widget.model.addListener(_updateModel);
      _updateTime();
      _updateModel();
      initTetrisData2();
    });
  }

  @override
  void didUpdateWidget(TetrisClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {});
  }

  Future<void> initTetrisData() async {
    String jsonData;
    // Splash Screen
    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/splash_screen.json");
    tetrisSplashScreen = jsonDecode(jsonData);
  }

  Future<void> initTetrisData2() async {
    String jsonData;
    // run tetrisSplashScreen until data is loaded

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/tetris_blocks.json");
    tetrisBlocks = jsonDecode(jsonData);

    tetrisNumberAnimationData = List();
    for (int i = 0; i < 10; i++) {
      jsonData = await DefaultAssetBundle.of(context)
          .loadString("assets/numbers/tetris_number$i.json");
      var numberAnimation = jsonDecode(jsonData);
      tetrisNumberAnimationData.add(numberAnimation);
    }

    // Weather animations
    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/sun.json");
    weatherSun = jsonDecode(jsonData);

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/cloudy.json");
    weatherCloudy = jsonDecode(jsonData);

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/rainy.json");
    weatherRainy = jsonDecode(jsonData);

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/thunderstorm.json");
    weatherThunderstorm = jsonDecode(jsonData);

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/snowy.json");
    weatherSnowy = jsonDecode(jsonData);

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/foggy.json");
    weatherFoggy = jsonDecode(jsonData);

    jsonData = await DefaultAssetBundle.of(context)
        .loadString("assets/weather/windy.json");
    weatherWindy = jsonDecode(jsonData);

    showSplashScreen = false;
    showSplashScreenOffAnimation = true;
  }

  void _updateTime() {
    setState(() {
      /* Set timer at the beginning to get a very stable interval */
      _dateTime = DateTime.now();
      int currentTimerDelay = _dateTime.millisecond % tetrisAnimationSpeed;

      _timer = Timer(
        Duration(milliseconds: tetrisAnimationSpeed - currentTimerDelay),
        _updateTime,
      );

      /* Refresh tetris grid data */
      updateTetrisGrid();
    });
  }

  @override
  Widget build(BuildContext context) {
    themeColors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    /*
    if (keepScreenOn) {
      Screen.keepOn(true);
      SystemChrome.setEnabledSystemUIOverlays([]);
    }
     */

    if (showSplashScreen) {
      var textColor = themeColors[_Element.text];
      return Stack(children: <Widget>[
        CustomPaint(
          painter: TetrisPainter(themeColors, tetrisGrid, tetrisPaint),
          child: Container(
            constraints: BoxConstraints.expand(),
          ),
        ),
        Container(
          padding: EdgeInsets.all(5.0),
          alignment: Alignment.bottomCenter,
          child: Text(
            "Made with ♡ by Michael Jentsch in Herne, Germany",
            style: TextStyle(color: textColor, fontSize: 16.0),
          ),
        )
      ]);
    } else {
      return CustomPaint(
        painter: TetrisPainter(themeColors, tetrisGrid, tetrisPaint),
        child: Container(
          constraints: BoxConstraints.expand(),
        ),
      );
    }
  }

  /* Refresh tetrisGrid. The array is needed to redraw the screen */
  void updateTetrisGrid() {
    if (showSplashScreen) {
      if (tetrisSplashScreen != null) {
        // tetrisGrid = tetrisSplashScreen;
        updateSplashScreen();
      }
    } else {
      cleanupTetrisGrid();
      if (showSplashScreenOffAnimation) {
        updateSplashScreenOffAnimation();
      }
      updateTetrisClockGrid();
    }
  }

  void updateSplashScreen() {
    for (int i = 0; i < tetrisRows; i++) {
      for (int j = 0; j < tetrisCols; j++) {
        tetrisGrid[i][j] = tetrisSplashScreen[i][j];
      }
    }
  }

  void updateSplashScreenOffAnimation() {
    if (splashScreenOffAnimationCounter < tetrisRows) {
      splashScreenOffAnimationCounter++;
      for (int i = 0; i < tetrisRows; i++) {
        for (int j = 0; j < tetrisCols; j++) {
          int yPos = j + splashScreenOffAnimationCounter;
          if (yPos < tetrisCols) {
            tetrisGrid[i][yPos] = tetrisSplashScreen[i][j];
          }
        }
      }
    } else {
      showSplashScreenOffAnimation = false;
    }
  }

  /* Add dot elements to tetrisGrid */
  void updateTetrisDots(int start, int end, bool show) {
    if (show) {
      updateDotWidgets(start, end, dotColor);
    } else {
      updateDotWidgets(start, end, empty);
    }
  }

  /* helper function for updateTetrisDots */
  void updateDotWidgets(int start, int end, int itemValue) {
    for (int i = start; i < end; i++) {
      tetrisGrid[i][12] = itemValue;
      tetrisGrid[i][13] = itemValue;
      tetrisGrid[i][16] = itemValue;
      tetrisGrid[i][17] = itemValue;
    }
  }

  void updateAmPm(int start, int end, int ampm) {
    int value = 0;
    switch (ampm) {
      case am:
        value = white;
        break;
      case pm:
        value = black;
        break;
    }

    for (int i = start; i <= end; i++) {
      tetrisGrid[i][18] = value;
      tetrisGrid[i][19] = value;
    }
  }

  void updateTetrisClockGrid() {
    // get current time values
    int h1 = _dateTime.hour ~/ 10;
    int h2 = _dateTime.hour % 10;
    int m1 = _dateTime.minute ~/ 10;
    int m2 = _dateTime.minute % 10;
    int s = _dateTime.second; // Needed for dots
    int ampm = 0; // AM/PM

    var showLastTetrisBlock = true;
    if (m1 == 5 && m2 == 9 && h1 == 2 && h2 == 23) {
      showLastTetrisBlock = false;
    }

    // Figure out next clock values
    DateTime _nextDateTime = _dateTime.add(new Duration(minutes: 1));
    int nh1 = _nextDateTime.hour ~/ 10;
    int nh2 = _nextDateTime.hour % 10;
    int nm1 = _nextDateTime.minute ~/ 10;
    int nm2 = _nextDateTime.minute % 10;

    // Calc. animation duration times in milliseconds
    int h1AnimationTime = getAnimationTime(h1, nh1);
    int h2AnimationTime = getAnimationTime(h2, nh2);
    int m1AnimationTime = getAnimationTime(m1, nm1);
    int m2AnimationTime = getAnimationTime(m2, nm2);

    // Start every animation with add. animation time
    h1 = _dateTime.add(new Duration(milliseconds: h1AnimationTime)).hour ~/ 10;
    h2 = _dateTime.add(new Duration(milliseconds: h2AnimationTime)).hour % 10;
    m1 =
        _dateTime.add(new Duration(milliseconds: m1AnimationTime)).minute ~/ 10;
    m2 = _dateTime.add(new Duration(milliseconds: m2AnimationTime)).minute % 10;

    if (!widget.model.is24HourFormat) {
      // Quick fix for 12 hour format
      int hour = h1 * 10 + h2;
      if (hour > 12) {
        hour -= 12;
        ampm = pm;
      } else {
        ampm = am;
      }
      h1 = hour ~/ 10;
      h2 = hour % 10;
    }

    if (h1 == 0 && hideTrailingHourZero) {
      // Do not use trailing 0 for hours
      h1 = -1;
    }

    if (showWeather) {
      updateWeatherCondition();
    }

    updateTetrisClockPart(9, 14, 0, h1, lh1, showLastTetrisBlock);
    updateTetrisClockPart(17, 22, 1, h2, lh2, showLastTetrisBlock);
    updateTetrisClockPart(29, 34, 2, m1, lm1, showLastTetrisBlock);
    updateTetrisClockPart(37, 42, 3, m2, lm2, showLastTetrisBlock);

    // Show/hide dots every second
    if (!showSplashScreenOffAnimation) {
      updateTetrisDots(25, 27, s % 2 == 0);
    }

    if (showAmPm) {
      updateAmPm(44, 45, ampm);
    }

    lm1 = m1;
    lm2 = m2;
    lh1 = h1;
    lh2 = h2;
  }

  void updateWeatherCondition() {
    weather = widget.model.weatherCondition;
    if (weather != lastWeather) {
      weatherAnimationCounter = 0;
      weatherOffset = maxWeatherOffset;
      outWeather = lastWeather;
    }

    if (weatherOffset < 0) {
      weatherOffset++;
      if (outWeather != null) {
        updateSelectedWeather(outWeather, -weatherOffset + maxWeatherOffset);
      }
    }
    updateSelectedWeather(weather, weatherOffset);

    weatherAnimationCounter++;
    lastWeather = weather;
  }

  void updateSelectedWeather(WeatherCondition weather, int offset) {
    switch (weather) {
      case WeatherCondition.sunny:
        updateWeather(weatherSun[0], weatherSun[1], offset);
        break;
      case WeatherCondition.cloudy:
        updateWeather(weatherCloudy[0], weatherCloudy[1], offset);
        break;
      case WeatherCondition.foggy:
        updateWeather(weatherFoggy[0], weatherFoggy[1], offset);
        break;
      case WeatherCondition.rainy:
        updateWeather(weatherRainy[0], weatherRainy[1], offset);
        break;
      case WeatherCondition.snowy:
        updateWeather(weatherSnowy[0], weatherSnowy[1], offset);
        break;
      case WeatherCondition.thunderstorm:
        updateWeather(weatherThunderstorm[0], weatherThunderstorm[1], offset);
        break;
      case WeatherCondition.windy:
        updateWeather(weatherWindy[0], weatherWindy[1], offset);
        break;
    }
  }

  void updateWeather(int animationSpeed, List weatherGrid, int offset) {
    int weatherAnimationStep =
        (_dateTime.millisecondsSinceEpoch / animationSpeed % weatherGrid.length)
            .toInt();
    for (int i = 0; i < weatherGrid[weatherAnimationStep].length; i++) {
      for (int j = 0; j < weatherGrid[weatherAnimationStep][i].length; j++) {
        if (weatherGrid[weatherAnimationStep][i][j] != empty) {
          int gridX = j + offset;
          int gridY = i;
          if (gridX >= 0 && gridY >= 0) {
            tetrisGrid[gridX][gridY] = weatherGrid[weatherAnimationStep][i][j];
          }
        }
      }
    }
  }

  void updateTetrisClockPart(int left, int right, int block, int number,
      int lastNumber, bool showLastTetrisBlock) {
    List<TetrisNumber> tetrisAnimationData =
        updateTetrisBlocks(block, number, lastNumber);
    if (number == -1) return;

    if (tetrisAnimationData.length > 1) {
      List lastBlockPosData = tetrisAnimationData[1].getLastBlockPosData();
      if (lastBlockPosData != null) {
        if (lastBlockPosData.length > 0) {
          int blockPosCounter = 0;
          for (var lastBlockPosElement in lastBlockPosData) {
            // Move blocks from blockPosElement to tetrisGrid
            var x = lastBlockPosElement[blx];
            var y = lastBlockPosElement[bly];
            var r = lastBlockPosElement[blr];
            var t = lastBlockPosElement[blt];
            List tetrisBlock = getRotatedBlockGrid(r, t);
            int color = tetrisAnimationData[1].getBlockColor(blockPosCounter);
            if (showLastTetrisBlock) {
              placeTetrisBlockOnGrid(tetrisBlock, x, y, left, right, color);
            }
            blockPosCounter++;
          }
        }
      }
    }

    List blockPosData = tetrisAnimationData[0].getBlockPosData();
    int blockPosCounter = 0;
    for (var blockPosElement in blockPosData) {
      // Move blocks from blockPosElement to tetrisGrid
      var x = blockPosElement[blx];
      var y = blockPosElement[bly];
      var r = blockPosElement[blr];
      var t = blockPosElement[blt];
      List tetrisBlock = getRotatedBlockGrid(r, t);
      int color = tetrisAnimationData[0].getBlockColor(blockPosCounter);
      placeTetrisBlockOnGrid(tetrisBlock, x, y, left, right, color);
      blockPosCounter++;
    }
  }

  void placeTetrisBlockOnGrid(
      List rotatedTetrisBlock, int x, int y, int left, int right, int color) {
    int xPos = 0;
    int yPos = 0;
    for (int yy = 0; yy < rotatedTetrisBlock.length; yy++) {
      for (int xx = 0; xx < rotatedTetrisBlock[yy].length; xx++) {
        xPos = left + x + xx;
        yPos = y + yy;
        if (xPos >= 0 &&
            yPos >= 0 &&
            rotatedTetrisBlock[yy][xx] > 0 &&
            yPos < tetrisCols &&
            xPos < tetrisRows) {
          tetrisGrid[xPos][yPos] = color;
        }
      }
    }
  }

  List getRotatedBlockGrid(var rotation, var type) {
    List baseGrid = tetrisBlocks[type][rotation];
    return baseGrid;
  }

  List<TetrisNumber> updateTetrisBlocks(int block, int number, int lastNumber) {
    if (number == lastValue[block]) {
      // Same value as before
      return continueTetrisClockAnimation(block, number, lastNumber);
    } else {
      // Value has changed
      lastValue[block] = number;
      return startTetrisClockAnimation(block, number, lastNumber);
    }
  }

  List<TetrisNumber> startTetrisClockAnimation(
      int block, int currentNumber, int lastNumber) {
    // delay move out animation to keep old number as long as possible
    lastTetrisNumbers[block] = getTetrisNumberBlock(lastNumber, -9);

    // Init tetrisNumbersBlock with new number
    tetrisNumbers[block] = getTetrisNumberBlock(currentNumber, 0);

    // Execute the first step
    return continueTetrisClockAnimation(block, currentNumber, lastNumber);
  }

  List<TetrisNumber> continueTetrisClockAnimation(
      int block, int currentNumber, int lastNumber) {
    List<TetrisNumber> ret = List();
    if (currentNumber > -1 && tetrisNumbers[block] != null) {
      TetrisNumber blocks = tetrisNumbers[block];
      tetrisNumbers[block].incrementPos();
      ret.add(blocks);
    }

    if (lastNumber > -1 && lastTetrisNumbers[block] != null) {
      TetrisNumber lastBlocks = lastTetrisNumbers[block];
      lastTetrisNumbers[block].incrementPos();
      ret.add(lastBlocks);
    }
    return ret;
  }

  void cleanupTetrisGrid() {
    for (List tetrisRow in tetrisGrid) {
      for (int i = 0; i < tetrisRow.length; i++) {
        tetrisRow[i] = empty;
      }
    }
  }

  TetrisNumber getTetrisNumberBlock(int value, int pos) {
    if (value == -1) {
      return null;
    } else {
      return TetrisNumber(tetrisNumberAnimationData[value], pos);
    }
  }

  int getAnimationTime(int currentNum, int nextNum) {
    if (currentNum == nextNum) {
      return 0;
    } else {
      return calculateAnimation(nextNum);
    }
  }

  int calculateAnimation(int number) {
    // Count steps from first block in selected number animation
    int steps = tetrisNumberAnimationData[number][animationsteps][0].length;
    return steps * tetrisAnimationSpeed;
  }
}

class TetrisNumber {
  List blocks;
  List colors;
  int pos;
  List lastBlockData;

  TetrisNumber(List animationData, int pos) {
    this.blocks = animationData[animationsteps];
    this.colors = animationData[blockcolors];
    this.pos = pos;
  }

  int getPos() {
    return pos;
  }

  void setPos(int pos) {
    this.pos = pos;
  }

  void incrementPos() {
    if (blocks != null) {
      if (pos < blocks[0].length - 1) {
        pos++;
      }
    }
  }

  List getBlocks() {
    return blocks;
  }

  List getBlockPosData() {
    List blockData = List();
    if (blocks != null) {
      for (List block in blocks) {
        blockData.add(block[pos]);
      }
    }
    return blockData;
  }

  int getBlockColor(int num) {
    return colors[num];
  }

  /*
  * Improve performance be reusing the lastBlockData instead of reinitializing
  * every time
  */
  List getLastBlockPosData() {
    if (lastBlockData == null) {
      initLastBlockData();
    } else {
      updateLastBlockData();
    }

    return lastBlockData;
  }

  void initLastBlockData() {
    lastBlockData = List();
    int blockPos = max(0, pos);
    if (blockPos < tetrisCols) {
      if (blocks != null) {
        for (List block in blocks) {
          // Take the last position of the element
          List finalPosBlockElement = block[block.length - 1];
          List blockElement = List.generate(4, (_) => 0);
          // Make a copy of the element
          blockElement[blx] = finalPosBlockElement[blx];
          blockElement[bly] = finalPosBlockElement[bly] + blockPos;
          blockElement[blr] = finalPosBlockElement[blr];
          blockElement[blt] = finalPosBlockElement[blt];
          lastBlockData.add(blockElement);
        }
      }
    }
  }

  void updateLastBlockData() {
    int blockPos = max(0, pos);
    if (blockPos < tetrisCols && blockPos > 0) {
      for (List lastBlockElement in lastBlockData) {
        lastBlockElement[bly] = lastBlockElement[bly] + 1;
      }
    }
  }
}

class TetrisPainter extends CustomPainter {
  var themeColors;
  var tetrisGrid;
  var tetrisPaint;

  TetrisPainter(this.themeColors, this.tetrisGrid, this.tetrisPaint);

  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width / tetrisRows;
    double height = size.height / tetrisCols;
    Size borderSize = Size(width, height);
    Paint borderPaint = Paint();
    double border = width / 16;
    Size blockSize = Size(width - 2 * border, height - 2 * border);
    for (int i = 0; i < tetrisRows; i++) {
      for (int j = 0; j < tetrisCols; j++) {
        if (tetrisGrid[i][j] != null) {
          Paint paint1 = tetrisPaint[tetrisGrid[i][j]][0];
          Paint paint2 = tetrisPaint[tetrisGrid[i][j]][1];
          if (paint1 != null && paint2 != null) {
            var blockPos = Offset(width * i + border, height * j + border);
            Rect rect = blockPos & blockSize;
            Rect borderRect = Offset(width * i, height * j) & borderSize;
            borderPaint.color =
                paint2.color.withOpacity(themeColors[_Element.blockAlpha]);
            canvas.drawRect(borderRect, borderPaint);
            canvas.drawRect(rect, paint2);
            var path = Path();
            path.moveTo(rect.left, rect.bottom);
            path.lineTo(rect.right, rect.top);
            path.lineTo(rect.right, rect.bottom);
            path.close();
            canvas.drawPath(path, paint1);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
