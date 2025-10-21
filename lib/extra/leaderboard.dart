import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardManager {
  static Future<void> saveScore(String playerName, String difficulty, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'leaderboard_$difficulty';
    final data = prefs.getStringList(key) ?? [];
    
    final entry = '$playerName|$score|${DateTime.now().millisecondsSinceEpoch}';
    data.add(entry);
    
    data.sort((a, b) {
      final scoreA = int.parse(a.split('|')[1]);
      final scoreB = int.parse(b.split('|')[1]);
      return scoreB.compareTo(scoreA);
    });
    
    if (data.length > 10) {
      data.removeRange(10, data.length);
    }
    
    await prefs.setStringList(key, data);
  }

  static Future<List<LeaderboardEntry>> getLeaderboard(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'leaderboard_$difficulty';
    final data = prefs.getStringList(key) ?? [];
    
    return data.map((entry) {
      final parts = entry.split('|');
      return LeaderboardEntry(
        playerName: parts[0],
        score: int.parse(parts[1]),
        timestamp: int.parse(parts[2]),
      );
    }).toList();
  }

  static Future<String> getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('player_name') ?? 'Player';
  }

  static Future<void> savePlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', name);
  }
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final int timestamp;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.timestamp,
  });
}