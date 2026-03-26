class WordleCoinsData {
  final int totalCoins;
  final int totalCoinsEarned;
  final int totalCoinsSpent;

  WordleCoinsData({
    required this.totalCoins,
    required this.totalCoinsEarned,
    required this.totalCoinsSpent,
  });

  WordleCoinsData copyWith({
    int? totalCoins,
    int? totalCoinsEarned,
    int? totalCoinsSpent,
  }) {
    return WordleCoinsData(
      totalCoins: totalCoins ?? this.totalCoins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalCoinsSpent: totalCoinsSpent ?? this.totalCoinsSpent,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalCoins': totalCoins,
        'totalCoinsEarned': totalCoinsEarned,
        'totalCoinsSpent': totalCoinsSpent
      };

  factory WordleCoinsData.fromJson(Map<String, dynamic> json) =>
      WordleCoinsData(
        totalCoins: json['totalCoins'] ?? 50,
        totalCoinsEarned: json['totalCoinsEarned'] ?? 0,
        totalCoinsSpent: json['totalCoinsSpent'] ?? 0,
      );
}
