import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'blackjack_models.dart';
import 'blackjack_logic.dart';

class Game3Page extends StatefulWidget {
  const Game3Page({super.key});

  @override
  State<Game3Page> createState() => _Game3PageState();
}

class _Game3PageState extends State<Game3Page> {
  final BlackjackLogic _logic = BlackjackLogic();
  late BlackjackGame _game;
  final List<int> _betOptions = [1, 5, 10, 20, 50];
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  Timer? _playerTimer;
  final int _playerTimeLimit = 5; // 5 seconds
  DateTime? _turnStartTime;

  @override
  void initState() {
    super.initState();
    _game = _logic.initializeGame();
    print('Game initialized with money: ${_game.playerMoney}'); // Debug print
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/Avatar.mp4');
    _videoController
        .initialize()
        .then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          // Don't set looping or auto-play
          _videoController.setLooping(false);
          // Play video immediately when page opens
          _playVideo();
        })
        .catchError((error) {
          print('Video initialization error: ${error.toString()}');
        });
  }

  // Play video once when called
  void _playVideo() {
    if (_isVideoInitialized && !_videoController.value.isPlaying) {
      _videoController.seekTo(Duration.zero);
      _videoController.play();
    }
  }

  // Start timer for player move timeout
  void _startPlayerTimer() {
    _cancelPlayerTimer();
    _turnStartTime = DateTime.now();
    _playerTimer = Timer(Duration(seconds: _playerTimeLimit), () {
      if (_game.gameState == GameState.playing) {
        _playVideo();
      }
    });
  }

  // Cancel the player timer
  void _cancelPlayerTimer() {
    _playerTimer?.cancel();
    _playerTimer = null;
  }

  @override
  void dispose() {
    _cancelPlayerTimer();
    _videoController.dispose();
    super.dispose();
  }

  void _placeBet(int amount) {
    _cancelPlayerTimer();
    setState(() {
      _game = _logic.placeBet(_game, amount);
      print(
        'Bet placed: $amount, Remaining money: ${_game.playerMoney}, Hand bet: ${_game.currentHand.bet}',
      ); // Debug
    });
    _startPlayerTimer(); // Start timer after any user interaction
  }

  void _dealCards() {
    _cancelPlayerTimer();
    setState(() {
      _game = _logic.dealInitialCards(_game);
      if (_game.gameState == GameState.playing) {
        _startPlayerTimer();
      } else if (_game.gameState == GameState.gameOver) {
        // If game ended immediately (blackjack), play video
        _playVideo();
      }
    });
  }

  void _hit(int handIndex) {
    _cancelPlayerTimer();
    setState(() {
      _game = _logic.hit(_game, handIndex);
      _checkForHandCompletion();
    });
  }

  void _stand(int handIndex) {
    _cancelPlayerTimer();
    setState(() {
      _game = _logic.stand(_game, handIndex);
      _checkForHandCompletion();
    });
  }

  void _doubleDown(int handIndex) {
    _cancelPlayerTimer();
    setState(() {
      _game = _logic.doubleDown(_game, handIndex);
      _checkForHandCompletion();
    });
  }

  void _split(int handIndex) {
    _cancelPlayerTimer();
    setState(() {
      _game = _logic.split(_game, handIndex);
      if (_game.gameState == GameState.playing) {
        _startPlayerTimer();
      }
    });
  }

  void _checkForHandCompletion() {
    // Check if current hand is finished or if we moved to next hand
    if (_game.gameState == GameState.playing) {
      PlayerHand currentHand = _game.playerHands[_game.currentHandIndex];
      if (currentHand.isStanding || currentHand.isBusted) {
        // Hand is complete, play video
        _playVideo();
        // If there are more hands, start timer for next hand after a delay
        if (_game.hasMoreHands) {
          Timer(Duration(milliseconds: 1000), () {
            if (_game.gameState == GameState.playing) {
              _startPlayerTimer();
            }
          });
        }
      } else {
        // Hand continues, restart timer
        _startPlayerTimer();
      }
    } else if (_game.gameState == GameState.gameOver) {
      // Game/round finished, play video
      _playVideo();
    }
  }

  void _newGame() {
    _cancelPlayerTimer();
    int currentMoney = _game.playerMoney; // Store current money
    setState(() {
      _game = _logic.initializeGame();
      _game.playerMoney = currentMoney; // Keep money
    });
    // Start timer for new game interactions
    _startPlayerTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5132),
      appBar: AppBar(
        title: const Text('Blackjack', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F5132),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Video section - Top 30% - Show in original size
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child:
                  _isVideoInitialized
                      ? Center(
                        child: AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: VideoPlayer(_videoController),
                        ),
                      )
                      : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
            ),
          ),

          // Game section - Bottom 70%
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Money display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Money: \$${_game.playerMoney}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Dealer section
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Dealer',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score: ${_logic.getDealerDisplayScore(_game)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCardRow(
                          _game.dealerHand,
                          _game.gameState == GameState.playing,
                        ),
                      ],
                    ),
                  ),

                  // Player section
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Player',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            // Timer indicator for current player
                            if (_game.gameState == GameState.playing &&
                                _playerTimer != null)
                              _buildTimerIndicator(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_game.playerHands.isNotEmpty) ...[
                          for (
                            int i = 0;
                            i < _game.playerHands.length;
                            i++
                          ) ...[
                            _buildPlayerHand(i),
                            if (i < _game.playerHands.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // Controls section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildControls(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerIndicator() {
    return StreamBuilder<int>(
      stream: Stream.periodic(
        Duration(seconds: 1),
        (i) => i,
      ).take(_playerTimeLimit).map((i) => _playerTimeLimit - i - 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data! < 0) return Container();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: snapshot.data! <= 1 ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${snapshot.data!}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardRow(List<PlayingCard> cards, bool hideDealerCard) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            cards.asMap().entries.map((entry) {
              int index = entry.key;
              PlayingCard card = entry.value;
              bool shouldHide = hideDealerCard && index == 1;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildCard(card, shouldHide),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCard(PlayingCard card, bool hidden) {
    if (hidden) {
      return Container(
        width: 50,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: const Center(
          child: Text('?', style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
      );
    }

    Color cardColor =
        (card.suit == Suit.hearts || card.suit == Suit.diamonds)
            ? Colors.red
            : Colors.black;

    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.symbol,
            style: TextStyle(
              color: cardColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(color: cardColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHand(int handIndex) {
    PlayerHand hand = _game.playerHands[handIndex];
    bool isActive = _game.currentHandIndex == handIndex;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? Colors.yellow : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hand ${handIndex + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'Bet: \$${hand.bet}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                'Score: ${_logic.calculateHandValue(hand.cards)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildCardRow(hand.cards, false),
          if (hand.result.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hand.result,
              style: TextStyle(
                color:
                    hand.result.contains('Win')
                        ? Colors.green
                        : hand.result.contains('Lose')
                        ? Colors.red
                        : Colors.yellow,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_game.gameState == GameState.betting) {
      return Column(
        children: [
          const Text(
            'Place your bet:',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children:
                _betOptions
                    .map(
                      (amount) => ElevatedButton(
                        onPressed:
                            _game.playerMoney >= amount
                                ? () => _placeBet(amount)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text('\$$amount'),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          if (_game.playerHands.isNotEmpty && _game.playerHands.first.bet > 0)
            ElevatedButton(
              onPressed: _dealCards,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Deal Cards'),
            ),
        ],
      );
    }

    if (_game.gameState == GameState.playing) {
      PlayerHand currentHand = _game.playerHands[_game.currentHandIndex];
      bool canSplit = _logic.canSplit(_game, _game.currentHandIndex);
      bool canDoubleDown = _logic.canDoubleDown(_game, _game.currentHandIndex);

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _hit(_game.currentHandIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hit'),
              ),
              ElevatedButton(
                onPressed: () => _stand(_game.currentHandIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Stand'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (canDoubleDown)
                ElevatedButton(
                  onPressed: () => _doubleDown(_game.currentHandIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Double'),
                ),
              if (canSplit)
                ElevatedButton(
                  onPressed: () => _split(_game.currentHandIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Split'),
                ),
            ],
          ),
        ],
      );
    }

    if (_game.gameState == GameState.gameOver) {
      return Column(
        children: [
          Text(
            _game.gameResult,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _newGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('New Game'),
          ),
        ],
      );
    }

    return Container();
  }
}
