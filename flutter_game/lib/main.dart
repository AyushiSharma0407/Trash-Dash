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

class Bullet {
  double x;
  double y;
  double velocity;

  Bullet({required this.x, required this.y, required this.velocity});
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
  List<Bullet> bulletList = [];
  int score = 0;
  bool gameOver = false;
  bool isPlayerWalk1 = true;
  bool showAlternateBackground = false;

  @override
  void initState() {
    super.initState();
    startPlayerMovement();
    startSpawningTrash();
    startPlayerWalkingAnimation();
  }

  void startPlayerMovement() {
    if (!gameOver) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
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

    bulletList.removeWhere((bullet) {
      bool isColliding = bullet.x < playerXPosition + 50 &&
          bullet.x + 10 > playerXPosition &&
          bullet.y < playerYPosition + 100 &&
          bullet.y + 50 > playerYPosition;

      if (isColliding) {
        stopGame();
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
      if (score == 50) {
        startBulletSpawning();
      }
      if (score % 25 == 0 && score <= 100) {
        showAlternateBackground = true;
        Timer(Duration(milliseconds: 500), () {
          setState(() {
            showAlternateBackground = false;
          });
        });
      }
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
            'You could not save the ocean!\nYour Score: $score',
          ),
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

  void startBulletSpawning() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!gameOver) {
        double bulletX = Random().nextDouble() * MediaQuery.of(context).size.width;
        double bulletVelocity = Random().nextDouble() * 2 + 1;

        Bullet bullet = Bullet(x: bulletX, y: 0, velocity: bulletVelocity);
        setState(() {
          bulletList.add(bullet);
        });

        startBulletMovement(bullet);
      } else {
        timer.cancel();
      }
    });
  }

  void startBulletMovement(Bullet bullet) {
    Timer.periodic(Duration(milliseconds: 20), (timer) {
      if (!gameOver) {
        setState(() {
          bullet.y += bullet.velocity;

          if (bullet.y > MediaQuery.of(context).size.height) {
            bulletList.remove(bullet);
          }
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
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trash Dash',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'A game where you assist Torrent the Turtle in saving the Water World from the humans by collecting all the trash and saving him from the bullets',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Score: $score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 24), // Add some space (adjust as needed)
              ],
            ),
          ),
        ],
        centerTitle: false,
        backgroundColor: Colors.teal,
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
            // Original Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Alternate Background (overlapping)
            if (showAlternateBackground)
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('background25.png'),
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
            for (var bullet in bulletList)
              Positioned(
                left: bullet.x,
                top: bullet.y,
                child: Container(
                  width: 10,
                  height: 50,
                  color: Colors.red,
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
          ],
        ),
      ),
    );
  }
}
