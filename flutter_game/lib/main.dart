import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyGame());
}

class MyGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(),
    );
  }
}

class Trash {
  double x;
  double y;
  double velocity;

  Trash({required this.x, required this.y, required this.velocity});
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double playerYPosition = 0.0;
  double playerXPosition = 50.0;
  double playerSpeed = 1.0;
  List<Trash> trashList = [];
  int score = 0;
  bool gameOver = false;
  bool isPlayerWalk1 = true;

  @override
  void initState() {
    super.initState();
    startPlayerMovement();
    startSpawningTrash();
    startPlayerWalkingAnimation();
  }

  void startPlayerMovement() {
    if (!gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          playerYPosition -= playerSpeed;

          if (playerYPosition < -50) {
            regenerateScene();
          }

          checkCollisions();
        });
        startPlayerMovement();
      });
    }
  }

  void startSpawningTrash() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (!gameOver && score <= 99) {
        double trashX = Random().nextDouble() * MediaQuery.of(context).size.width;
        double trashY = Random().nextDouble() * MediaQuery.of(context).size.height;
        double trashVelocity = Random().nextDouble() * 2 - 1;

        trashX = max(0, min(trashX, MediaQuery.of(context).size.width - 50));
        trashY = max(0, min(trashY, MediaQuery.of(context).size.height - 50));

        Trash trash = Trash(x: trashX, y: trashY, velocity: trashVelocity);
        setState(() {
          trashList.add(trash);
        });

        startTrashMovement(trash);
      } else if (!gameOver) {
        wonGame();
      }
    });
  }

  void startTrashMovement(Trash trash) {
    Timer.periodic(Duration(milliseconds: 20), (timer) {
      if (!gameOver) {
        setState(() {
          trash.x += trash.velocity;

          if (trash.x < 0 || trash.x > MediaQuery.of(context).size.width - 50) {
            trash.velocity *= -1;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void regenerateScene() {
    setState(() {
      playerYPosition = MediaQuery.of(context).size.height - 50.0;
    });
  }

  void checkCollisions() {
    trashList.removeWhere((trash) {
      bool isColliding = playerXPosition < trash.x + 50 &&
          playerXPosition + 50 > trash.x &&
          playerYPosition < trash.y + 50 &&
          playerYPosition + 100 > trash.y;

      if (isColliding) {
        increaseScore();
      }

      return isColliding;
    });

    if (!gameOver && trashList.length > 12) {
      stopGame();
    }
  }

  void increaseScore() {
    setState(() {
      score++;
    });
  }

  void stopGame() {
    setState(() {
      playerSpeed = 0.0;
      gameOver = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text(
              'You let too much trash accumulate!\nYour Score: $score'),
        );
      },
    );
  }

  void wonGame() {
    setState(() {
      playerSpeed = 0.0;
      gameOver = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('You won'),
          content: Text('You saved the turtles!\nYour Score: $score'),
        );
      },
    );
  }

  void startPlayerWalkingAnimation() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!gameOver) {
        setState(() {
          isPlayerWalk1 = !isPlayerWalk1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trash Dash'),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (!gameOver && event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              setState(() {
                playerXPosition = max(0, playerXPosition - 10.0);
              });
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              setState(() {
                playerXPosition = min(screenWidth - 50, playerXPosition + 10.0);
              });
            }
          }
        },
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Other game elements
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 0,
                color: Colors.green,
              ),
            ),
            for (var trash in trashList)
              Positioned(
                left: trash.x,
                top: trash.y,
                child: Image.asset(
                  'trash.png',
                  width: 50,
                  height: 50,
                ),
              ),
            Positioned(
              left: playerXPosition,
              top: playerYPosition,
              child: Image.asset(
                isPlayerWalk1 ? 'turtle1.png' : 'turtle2.png',
                width: 100,
                height: 100,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Score: $score',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

