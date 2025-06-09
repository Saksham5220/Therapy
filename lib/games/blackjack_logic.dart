import 'blackjack_models.dart';

class BlackjackLogic {
  BlackjackGame initializeGame() {
    BlackjackGame game = BlackjackGame();
    game.reset();
    return game;
  }

  BlackjackGame placeBet(BlackjackGame game, int amount) {
    if (game.gameState == GameState.betting && game.playerMoney >= amount) {
      game.currentHand.bet += amount;
      game.playerMoney -= amount;
    }
    return game;
  }

  BlackjackGame dealInitialCards(BlackjackGame game) {
    if (game.gameState == GameState.betting && game.currentHand.bet > 0) {
      // Deal two cards to player
      game.currentHand.addCard(game.deck.dealCard());
      game.currentHand.addCard(game.deck.dealCard());

      // Deal two cards to dealer
      game.dealerHand.add(game.deck.dealCard());
      game.dealerHand.add(game.deck.dealCard());

      game.gameState = GameState.playing;

      // Check for blackjacks
      if (game.currentHand.isBlackjack) {
        if (calculateHandValue(game.dealerHand) == 21) {
          // Push
          game.currentHand.result = 'Push';
          game.playerMoney += game.currentHand.bet;
        } else {
          // Player blackjack wins
          game.currentHand.result = 'Blackjack!';
          game.playerMoney += (game.currentHand.bet * 2.5).round();
        }
        _finishGame(game);
      }
    }
    return game;
  }

  BlackjackGame hit(BlackjackGame game, int handIndex) {
    if (game.gameState == GameState.playing &&
        handIndex == game.currentHandIndex) {
      PlayerHand hand = game.playerHands[handIndex];
      hand.addCard(game.deck.dealCard());

      if (hand.isBusted) {
        hand.result = 'Bust';
        hand.isStanding = true;
        _checkNextHand(game);
      }
    }
    return game;
  }

  BlackjackGame stand(BlackjackGame game, int handIndex) {
    if (game.gameState == GameState.playing &&
        handIndex == game.currentHandIndex) {
      game.playerHands[handIndex].isStanding = true;
      _checkNextHand(game);
    }
    return game;
  }

  BlackjackGame doubleDown(BlackjackGame game, int handIndex) {
    if (canDoubleDown(game, handIndex)) {
      PlayerHand hand = game.playerHands[handIndex];

      // Double the bet
      game.playerMoney -= hand.bet;
      hand.bet *= 2;
      hand.isDoubledDown = true;

      // Deal one more card
      hand.addCard(game.deck.dealCard());
      hand.isStanding = true;

      if (hand.isBusted) {
        hand.result = 'Bust';
      }

      _checkNextHand(game);
    }
    return game;
  }

  BlackjackGame split(BlackjackGame game, int handIndex) {
    if (canSplit(game, handIndex)) {
      PlayerHand originalHand = game.playerHands[handIndex];

      // Create new hand with second card
      PlayerHand newHand = PlayerHand(bet: originalHand.bet);
      newHand.addCard(originalHand.cards.removeLast());

      // Deduct money for second bet
      game.playerMoney -= originalHand.bet;

      // Add card to each hand
      originalHand.addCard(game.deck.dealCard());
      newHand.addCard(game.deck.dealCard());

      // Insert new hand after current hand
      game.playerHands.insert(handIndex + 1, newHand);
    }
    return game;
  }

  bool canSplit(BlackjackGame game, int handIndex) {
    if (game.gameState != GameState.playing ||
        handIndex != game.currentHandIndex) {
      return false;
    }

    PlayerHand hand = game.playerHands[handIndex];

    return hand.cards.length == 2 &&
        hand.cards[0].rank == hand.cards[1].rank &&
        game.playerMoney >= hand.bet &&
        !hand.isDoubledDown;
  }

  bool canDoubleDown(BlackjackGame game, int handIndex) {
    if (game.gameState != GameState.playing ||
        handIndex != game.currentHandIndex) {
      return false;
    }

    PlayerHand hand = game.playerHands[handIndex];

    return hand.cards.length == 2 &&
        game.playerMoney >= hand.bet &&
        !hand.isStanding;
  }

  void _checkNextHand(BlackjackGame game) {
    if (game.hasMoreHands) {
      game.nextHand();
    } else {
      _playDealerHand(game);
    }
  }

  void _playDealerHand(BlackjackGame game) {
    game.gameState = GameState.dealerTurn;

    // Check if any player hands are still in play (not busted)
    bool anyPlayerHandActive = game.playerHands.any(
      (hand) => !hand.isBusted && hand.result.isEmpty,
    );

    if (anyPlayerHandActive) {
      // Dealer must hit on soft 17 and below
      while (calculateHandValue(game.dealerHand) < 17) {
        game.dealerHand.add(game.deck.dealCard());
      }
    }

    _finishGame(game);
  }

  void _finishGame(BlackjackGame game) {
    int dealerValue = calculateHandValue(game.dealerHand);
    bool dealerBusted = dealerValue > 21;

    for (PlayerHand hand in game.playerHands) {
      if (hand.result.isNotEmpty) {
        continue; // Already determined (blackjack, bust, etc.)
      }

      int handValue = calculateHandValue(hand.cards);

      if (hand.isBusted) {
        hand.result = 'Bust - Lose';
      } else if (dealerBusted) {
        hand.result = 'Dealer Bust - Win';
        game.playerMoney += hand.bet * 2;
      } else if (handValue > dealerValue) {
        hand.result = 'Win';
        game.playerMoney += hand.bet * 2;
      } else if (handValue == dealerValue) {
        hand.result = 'Push';
        game.playerMoney += hand.bet;
      } else {
        hand.result = 'Lose';
      }
    }

    // Determine overall game result
    List<String> results = game.playerHands.map((h) => h.result).toList();
    if (results.every((r) => r.contains('Win') || r.contains('Blackjack'))) {
      game.gameResult = 'You Win!';
    } else if (results.every((r) => r.contains('Lose') || r.contains('Bust'))) {
      game.gameResult = 'You Lose!';
    } else {
      game.gameResult = 'Mixed Results';
    }

    game.gameState = GameState.gameOver;
  }

  int calculateHandValue(List<PlayingCard> cards) {
    int value = 0;
    int aces = 0;

    // First, add all non-ace cards
    for (PlayingCard card in cards) {
      if (card.rank == Rank.ace) {
        aces++;
      } else {
        value += card.rank.value;
      }
    }

    // Add aces - start with 11, convert to 1 if needed
    for (int i = 0; i < aces; i++) {
      if (value + 11 <= 21) {
        value += 11; // Use ace as 11
      } else {
        value += 1; // Use ace as 1
      }
    }

    return value;
  }

  String getDealerDisplayScore(BlackjackGame game) {
    if (game.gameState == GameState.playing) {
      // Only show first card value during player turn
      return game.dealerHand.isNotEmpty
          ? '${game.dealerHand[0].rank.value}+'
          : '0';
    } else {
      return calculateHandValue(game.dealerHand).toString();
    }
  }
}
