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

  @override
  void initState() {
    super.initState();
    // Start player movement
    startPlayerMovement();
    // Start spawning trash
    startSpawningTrash();
  }

  void startPlayerMovement() {
    if (!gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          playerYPosition -= playerSpeed;

          // Regenerate player at the bottom when reaching the top
          if (playerYPosition < -50) {
            regenerateScene();
          }

          // Check for collisions with trash
          checkCollisions();
        });
        startPlayerMovement();
      });
    }
  }

  void startSpawningTrash() {
    // Randomly spawn trash
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (!gameOver && score <= 99) {
        double trashX = Random().nextDouble() * MediaQuery.of(context).size.width;
        double trashY = Random().nextDouble() * MediaQuery.of(context).size.height;
        double trashVelocity = Random().nextDouble() * 2 - 1; // Random velocity between -1 and 1

        // Ensure trash spawns only within the visible screen area
        trashX = max(0, min(trashX, MediaQuery.of(context).size.width - 50));
        trashY = max(0, min(trashY, MediaQuery.of(context).size.height - 50));

        Trash trash = Trash(x: trashX, y: trashY, velocity: trashVelocity);
        setState(() {
          trashList.add(trash);
        });

        // Start the timer to move the trash
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
          // Update the trash position based on velocity
          trash.x += trash.velocity;

          // Check if trash goes out of bounds, and change its direction
          if (trash.x < 0 || trash.x > MediaQuery.of(context).size.width - 50) {
            trash.velocity *= -1;
          }
        });
      } else {
        timer.cancel(); // Stop the timer when the game is over
      }
    });
  }

  void regenerateScene() {
    setState(() {
      playerYPosition = MediaQuery.of(context).size.height - 50.0;
    });
  }

  void checkCollisions() {
    // Check for collisions with trash
    trashList.removeWhere((trash) {
      bool isColliding = playerXPosition < trash.x + 50 &&
          playerXPosition + 50 > trash.x &&
          playerYPosition < trash.y + 50 &&
          playerYPosition + 50 > trash.y;

      if (isColliding) {
        // Do something when the player collects the trash
        increaseScore();
      }

      return isColliding;
    });

    // Check if the number of trash objects exceeds 12
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
      playerSpeed = 0.0; // Stop player movement
      gameOver = true;
    });

    // Display game over message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text('You let too much trash accumulate!\nYour Score: $score'),
        );
      },
    );
  }

  void wonGame() {
    setState(() {
      playerSpeed = 0.0; // Stop player movement
      gameOver = true;
    });

    // Display game over message
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
          // Move player left or right using arrow keys
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
        child: AnimatedContainer(
          duration: Duration(milliseconds: 20),
          color: Colors.blue,
          child: Stack(
            children: [
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 0,
                  color: Colors.green,
                ),
              ),
              // Player
              Positioned(
                left: playerXPosition,
                top: playerYPosition, // Adjusted to be visible on the screen
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.red,
                ),
              ),
              // Trash
              for (var trash in trashList)
                Positioned(
                  left: trash.x,
                  top: trash.y,
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey,
                  ),
                ),
              // Score
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
      ),
    );
  }
}
