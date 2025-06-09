import 'package:flutter/material.dart';

// Import game home pages - add more as needed
import 'game1_home.dart';
import 'game2.dart';
import 'game3.dart';
// import 'game4.dart';
// import 'game5.dart';
// import 'game6.dart';
// import 'game7.dart';
// import 'game8.dart';
// import 'game9.dart';
// import 'game10.dart';

class Game {
  final String title;
  final String? image;
  final Widget? page;
  final String? description;

  Game({required this.title, this.image, this.page, this.description});
}

final List<Game> availableGames = [
  Game(
    title: 'PAC-MAN',
    image: 'assets/images/game1.png',
    page: const GameHomePage(), // Use the home page instead of direct game
    description: 'Classic arcade maze game - eat dots and avoid ghosts!',
  ),
  Game(
    title: 'Memory Match',
    image: 'assets/images/game2.png',
    page: const Game2Page(),
    description: 'Test your memory skills',
  ),
  Game(
    title: 'Word Quest',
    image: 'assets/images/game3.png',
    page: const Game3Page(),
    description: 'Find words and expand vocabulary',
  ),
  // Game(
  //   title: 'Number Ninja',
  //   image: 'assets/images/game4.png',
  //   page: const Game4Page(),
  //   description: 'Math challenges and number games',
  // ),
  // Game(
  //   title: 'Color Rush',
  //   image: 'assets/images/game5.png',
  //   page: const Game5Page(),
  //   description: 'Fast-paced color matching',
  // ),
  // Game(
  //   title: 'Logic Lab',
  //   image: 'assets/images/game6.png',
  //   page: const Game6Page(),
  //   description: 'Brain training logic puzzles',
  // ),
  // Game(
  //   title: 'Speed Tap',
  //   image: 'assets/images/game7.png',
  //   page: const Game7Page(),
  //   description: 'Test your reaction speed',
  // ),
  // Game(
  //   title: 'Pattern Pro',
  //   image: 'assets/images/game8.png',
  //   page: const Game8Page(),
  //   description: 'Recognize and complete patterns',
  // ),
  // Game(
  //   title: 'Quiz Champion',
  //   image: 'assets/images/game9.png',
  //   page: const Game9Page(),
  //   description: 'General knowledge trivia',
  // ),
  // Game(
  //   title: 'Strategy Master',
  //   image: 'assets/images/game10.png',
  //   page: const Game10Page(),
  //   description: 'Strategic thinking challenges',
  // ),
];

// Helper function to get available games
List<Game> getAvailableGames() {
  List<Game> games = [];

  // Check which games exist and add them
  try {
    games.add(availableGames[0]); // Game 1 - PAC-MAN
  } catch (e) {
    // GameHomePage doesn't exist, skip
  }

  try {
    games.add(availableGames[1]); // Game 2
  } catch (e) {
    // Game2Page doesn't exist, skip
  }

  try {
    games.add(availableGames[2]); // Game 3
  } catch (e) {
    // Game3Page doesn't exist, skip
  }

  try {
    games.add(availableGames[3]); // Game 4
  } catch (e) {
    // Game4Page doesn't exist, skip
  }

  try {
    games.add(availableGames[4]); // Game 5
  } catch (e) {
    // Game5Page doesn't exist, skip
  }

  try {
    games.add(availableGames[5]); // Game 6
  } catch (e) {
    // Game6Page doesn't exist, skip
  }

  try {
    games.add(availableGames[6]); // Game 7
  } catch (e) {
    // Game7Page doesn't exist, skip
  }

  try {
    games.add(availableGames[7]); // Game 8
  } catch (e) {
    // Game8Page doesn't exist, skip
  }

  try {
    games.add(availableGames[8]); // Game 9
  } catch (e) {
    // Game9Page doesn't exist, skip
  }

  try {
    games.add(availableGames[9]); // Game 10
  } catch (e) {
    // Game10Page doesn't exist, skip
  }

  return games;
}

// Alternative approach - dynamically check which games exist
List<Game> getExistingGames() {
  List<Game> existingGames = [];

  // This approach requires you to manually comment/uncomment based on existing files

  // Uncomment the games that exist in your project:

  existingGames.add(
    Game(
      title: 'PAC-MAN',
      image: 'assets/images/pacman.png',
      page: const GameHomePage(), // This navigates to the Pac-Man home screen
      description: 'Classic arcade maze game - eat dots and avoid ghosts!',
    ),
  );

  existingGames.add(
    Game(
      title: 'Memory Match',
      image: 'assets/images/game2.png',
      page: const Game2Page(),
      description: 'Test your memory skills',
    ),
  );

  existingGames.add(
    Game(
      title: 'Blackjack',
      image: 'assets/images/game3.png',
      page: const Game3Page(),
    ),
  );

  // Add more games as you create them:
  /*
  existingGames.add(Game(
    title: 'Number Ninja',
    image: 'assets/images/game4.png',
    page: const Game4Page(),
  ));
  
  existingGames.add(Game(
    title: 'Color Rush',
    image: 'assets/images/game5.png',
    page: const Game5Page(),  
  ));
  
  existingGames.add(Game(
    title: 'Logic Lab',
    image: 'assets/images/game6.png',
    page: const Game6Page(),
  ));
  
  existingGames.add(Game(
    title: 'Speed Tap',
    image: 'assets/images/game7.png',
    page: const Game7Page(),
  ));
  
  existingGames.add(Game(
    title: 'Pattern Pro', 
    image: 'assets/images/game8.png',
    page: const Game8Page(),
  ));
  
  existingGames.add(Game(
    title: 'Quiz Champion',
    image: 'assets/images/game9.png',
    page: const Game9Page(),
  ));
  
  existingGames.add(Game(
    title: 'Strategy Master',
    image: 'assets/images/game10.png', 
    page: const Game10Page(),
  ));
  */

  return existingGames;
}
