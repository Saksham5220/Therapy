enum Suit {
  hearts('♥'),
  diamonds('♦'),
  clubs('♣'),
  spades('♠');

  const Suit(this.symbol);
  final String symbol;
}

enum Rank {
  ace('A', 11),
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 10),
  queen('Q', 10),
  king('K', 10);

  const Rank(this.symbol, this.value);
  final String symbol;
  final int value;
}

class PlayingCard {
  final Suit suit;
  final Rank rank;

  PlayingCard(this.suit, this.rank);

  @override
  String toString() => '${rank.symbol}${suit.symbol}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingCard && other.suit == suit && other.rank == rank;
  }

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;
}

class Deck {
  List<PlayingCard> cards = [];

  Deck() {
    _initializeDeck();
    shuffle();
  }

  void _initializeDeck() {
    cards.clear();
    for (Suit suit in Suit.values) {
      for (Rank rank in Rank.values) {
        cards.add(PlayingCard(suit, rank));
      }
    }
  }

  void shuffle() {
    cards.shuffle();
  }

  PlayingCard dealCard() {
    if (cards.isEmpty) {
      _initializeDeck();
      shuffle();
    }
    return cards.removeLast();
  }

  bool get isEmpty => cards.isEmpty;
}

class PlayerHand {
  List<PlayingCard> cards = [];
  int bet = 0;
  bool isStanding = false;
  bool isDoubledDown = false;
  String result = '';

  PlayerHand({this.bet = 0});

  PlayerHand.fromHand(PlayerHand other) {
    cards = List.from(other.cards);
    bet = other.bet;
    isStanding = other.isStanding;
    isDoubledDown = other.isDoubledDown;
    result = other.result;
  }

  void addCard(PlayingCard card) {
    cards.add(card);
  }

  void clear() {
    cards.clear();
    isStanding = false;
    isDoubledDown = false;
    result = '';
  }

  bool get isEmpty => cards.isEmpty;
  bool get isBlackjack => cards.length == 2 && calculateValue() == 21;

  int calculateValue() {
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

  bool get isBusted => calculateValue() > 21;
}

enum GameState { betting, playing, dealerTurn, gameOver }

class BlackjackGame {
  Deck deck = Deck();
  List<PlayingCard> dealerHand = [];
  List<PlayerHand> playerHands = [];
  int currentHandIndex = 0;
  GameState gameState = GameState.betting;
  int playerMoney = 1000;
  String gameResult = '';

  BlackjackGame() {
    playerHands.add(PlayerHand());
  }

  void reset() {
    deck = Deck();
    dealerHand.clear();
    playerHands.clear();
    playerHands.add(PlayerHand());
    currentHandIndex = 0;
    gameState = GameState.betting;
    gameResult = '';
  }

  bool get isGameOver => gameState == GameState.gameOver;

  PlayerHand get currentHand => playerHands[currentHandIndex];

  bool get hasMoreHands => currentHandIndex < playerHands.length - 1;

  void nextHand() {
    if (hasMoreHands) {
      currentHandIndex++;
    }
  }

  int get totalBet {
    return playerHands.fold(0, (sum, hand) => sum + hand.bet);
  }
}
