import 'package:flutter/material.dart';
import '../extra/leaderboard.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String playerName = 'Player';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final name = await LeaderboardManager.getPlayerName();
    setState(() => playerName = name);
  }

  Future<void> _changePlayerName() async {
    final controller = TextEditingController(text: playerName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Player Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name', border: OutlineInputBorder()),
          maxLength: 15,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await LeaderboardManager.savePlayerName(result);
      setState(() => playerName = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF283593), Color(0xFF3949ab)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                    const Expanded(child: Text('🏆 Leaderboard', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _changePlayerName,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(playerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 10),
                      const Icon(Icons.edit, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [Tab(text: 'Easy'), Tab(text: 'Normal'), Tab(text: 'Hard')],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList('Easy'),
                    _buildLeaderboardList('Normal'),
                    _buildLeaderboardList('Hard'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String difficulty) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: LeaderboardManager.getLeaderboard(difficulty),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No scores yet!\nPlay to be the first! 🎮', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white70)));
        }

        final entries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isCurrentPlayer = entry.playerName == playerName;
            
            Color rankColor = Colors.white70;
            String medal = '';
            if (index == 0) { rankColor = const Color(0xFFFFD700); medal = '🥇'; }
            else if (index == 1) { rankColor = const Color(0xFFC0C0C0); medal = '🥈'; }
            else if (index == 2) { rankColor = const Color(0xFFCD7F32); medal = '🥉'; }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentPlayer ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isCurrentPlayer ? Colors.blue : Colors.white.withOpacity(0.2), width: isCurrentPlayer ? 2 : 1),
              ),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text(medal.isEmpty ? '#${index + 1}' : medal, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: rankColor))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.playerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isCurrentPlayer ? Colors.white : Colors.white70)),
                        Text(_formatDate(entry.timestamp), style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                    child: Text('${entry.score}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}