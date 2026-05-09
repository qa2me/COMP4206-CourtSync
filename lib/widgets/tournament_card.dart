import 'package:flutter/material.dart';
import '../services/database_service.dart';



Color getSpotsColor(int spotsLeft) {
  if (spotsLeft < 2) {
    return Colors.red.shade300;
  } else if (spotsLeft <= 4) {
    return Colors.yellow.shade700;
  } else {
    return Colors.green;
  }
}

Widget TournamentCard(item, context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black,
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          height: 90,
          child: Image.asset(
            item.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A2A4A),
              child: const Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A2A4A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: getSpotsColor(item.spotsLeft),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.spotsLeft} Spots Left',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        item.venue,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.entryFee != null && item.entryFee! > 0
                          ? '\$${item.entryFee!.toStringAsFixed(2)}'
                          : 'Free',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.group_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join ${item.name}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2A4A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('Venue: ${item.venue}'),
                              Text('Entry Fee: ${item.entryFee != null && item.entryFee! > 0 ? '\$${item.entryFee!.toStringAsFixed(2)}' : 'Free'}'),
                              Text('Spots Left: ${item.spotsLeft}'),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final uid = DatabaseService.instance.currentUser?.uid;
                                      if (uid == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please sign in first')),
                                        );
                                        return;
                                      }
                                      DatabaseService.instance.joinTournament(uid, item.id).then((_) {
                                        if (context.mounted) Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Joined ${item.name}!')),
                                        );
                                      }).catchError((e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to join: $e')),
                                        );
                                      });
                                    },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A2A4A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Confirm Join'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 15),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}