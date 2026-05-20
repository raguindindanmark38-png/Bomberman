import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF545050),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F3B3B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'LEADERBOARD',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaderboards')
            .orderBy('score', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final scores = snapshot.data!.docs;

          if (scores.isEmpty) {
            return const Center(
              child: Text(
                'NO SCORES YET',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final data = scores[index].data() as Map<String, dynamic>;

              final name = data['fullName'] ?? 'Player';
              final score = data['score'] ?? 0;
              final difficulty = data['difficulty'] ?? 'Easy';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 14),

                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.black,
                      backgroundImage:
                          (data['photoUrl'] ?? '').toString().isNotEmpty
                          ? NetworkImage(data['photoUrl'])
                          : null,
                      child: (data['photoUrl'] ?? '').toString().isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            difficulty.toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
