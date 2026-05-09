enum TournamentStatus { upcoming, ongoing, completed }
enum TournamentMatchType { singles, doubles, both }
enum TournamentFormat { singleElimination, doubleElimination, roundRobin, swiss }
class Tournament {
  final String id;
  final String name;
  final String description;
  final String venue;
  final String location;
  final String startDate;
  final String endDate;
  final String startTime;
  final TournamentStatus status;
  final TournamentMatchType matchType;
  final TournamentFormat format;
  final bool isFree;
  final double? entryFee;
  final String? prize;
  final int spotsTotal;
  final int spotsLeft;
  final String imagePath;
  final bool isCreatedByMe;
  bool isJoined;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.venue,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.status,
    required this.matchType,
    required this.format,
    required this.isFree,
    this.entryFee,
    this.prize,
    required this.spotsTotal,
    required this.spotsLeft,
    required this.imagePath,
    required this.isCreatedByMe,
    this.isJoined = false,
  });
}