import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tournament.dart';
import '../services/database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy  = Color(0xFF1A2A4A);
const Color _kGreen = Color(0xFF4CAF50);
const Color _kBg    = Color(0xFFF4F6F9);
const Color _kRed   = Color(0xFFE53935);
const Color _kGold  = Color(0xFFFFD700);
const Color _kBlue  = Color(0xFF2196F3);

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & MODEL
// ─────────────────────────────────────────────────────────────────────────────


extension TournamentStatusExt on TournamentStatus {
  String get label {
    switch (this) {
      case TournamentStatus.upcoming:  return 'Upcoming';
      case TournamentStatus.ongoing:   return 'Ongoing';
      case TournamentStatus.completed: return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case TournamentStatus.upcoming:  return _kBlue;
      case TournamentStatus.ongoing:   return _kGreen;
      case TournamentStatus.completed: return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case TournamentStatus.upcoming:  return Icons.schedule_rounded;
      case TournamentStatus.ongoing:   return Icons.play_circle_rounded;
      case TournamentStatus.completed: return Icons.check_circle_rounded;
    }
  }
}

extension TournamentMatchTypeExt on TournamentMatchType {
  String get label {
    switch (this) {
      case TournamentMatchType.singles: return 'Singles';
      case TournamentMatchType.doubles: return 'Doubles';
      case TournamentMatchType.both:    return 'Singles & Doubles';
    }
  }
}

extension TournamentFormatExt on TournamentFormat {
  String get label {
    switch (this) {
      case TournamentFormat.singleElimination: return 'Single Elimination';
      case TournamentFormat.doubleElimination: return 'Double Elimination';
      case TournamentFormat.roundRobin:        return 'Round Robin';
      case TournamentFormat.swiss:             return 'Swiss';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ViewTournamentPage extends StatefulWidget {
  const ViewTournamentPage({super.key});

  @override
  State<ViewTournamentPage> createState() => _ViewTournamentPageState();
}

class _ViewTournamentPageState extends State<ViewTournamentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Tournament> _tournaments = [];
  Set<String> _joinedIds = {};
  StreamSubscription? _regsSub;

  // Filters
  TournamentStatus?   _statusFilter;
  TournamentMatchType? _matchTypeFilter;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    DatabaseService.instance.tournamentsStream.listen((list) {
      if (mounted) {
        setState(() {
          _tournaments = list.map((d) => Tournament(
            id: d['id'] ?? '',
            name: d['name'] ?? '',
            description: d['description'] ?? '',
            venue: d['venue'] ?? '',
            location: d['location'] ?? '',
            startDate: d['startDate'] ?? '',
            endDate: d['endDate'] ?? '',
            startTime: d['startTime'] ?? '',
            status: _parseStatus(d['status']),
            matchType: _parseMatchType(d['matchType']),
            format: _parseFormat(d['format']),
            isFree: d['isFree'] ?? true,
            entryFee: (d['entryFee'] as num?)?.toDouble(),
            prize: d['prize'] as String?,
            spotsTotal: (d['spotsTotal'] ?? 0) as int,
            spotsLeft: (d['spotsLeft'] ?? 0) as int,
            imagePath: d['imagePath'] ?? 'assets/images/court1.png',
            isCreatedByMe: d['isCreatedByMe'] ?? false,
            isJoined: _joinedIds.contains(d['id'] ?? ''),
          )).toList();
        });
      }
    });
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      _regsSub = DatabaseService.instance.userTournamentRegistrationsStream(uid).listen((ids) {
        _joinedIds = ids;
        setState(() {
          for (final t in _tournaments) {
            t.isJoined = ids.contains(t.id);
          }
        });
      });
    }
  }

  TournamentStatus _parseStatus(String? s) {
    switch (s) {
      case 'upcoming': return TournamentStatus.upcoming;
      case 'ongoing': return TournamentStatus.ongoing;
      case 'completed': return TournamentStatus.completed;
      default: return TournamentStatus.upcoming;
    }
  }

  TournamentMatchType _parseMatchType(String? s) {
    switch (s) {
      case 'singles': return TournamentMatchType.singles;
      case 'doubles': return TournamentMatchType.doubles;
      case 'both': return TournamentMatchType.both;
      default: return TournamentMatchType.singles;
    }
  }

  TournamentFormat _parseFormat(String? s) {
    switch (s) {
      case 'singleElimination': return TournamentFormat.singleElimination;
      case 'doubleElimination': return TournamentFormat.doubleElimination;
      case 'roundRobin': return TournamentFormat.roundRobin;
      case 'swiss': return TournamentFormat.swiss;
      default: return TournamentFormat.singleElimination;
    }
  }

  @override
  void dispose() {
    _regsSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Filtered lists ─────────────────────────────────────────────────────────
  List<Tournament> get _filtered {
    return _tournaments.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_matchTypeFilter != null && t.matchType != _matchTypeFilter) return false;
      return true;
    }).toList();
  }

  List<Tournament> get _myFiltered {
    return _filtered.where((t) => t.isCreatedByMe || t.isJoined).toList();
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _joinTournament(Tournament t) async {
    if (_joinedIds.contains(t.id)) return;
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await DatabaseService.instance.joinTournament(uid, t.id);
      if (!mounted) return;
      setState(() => t.isJoined = true);
      _snack('You joined ${t.name}!', isError: false);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to join: $e', isError: true);
    }
  }

  Future<void> _withdrawTournament(Tournament t) async {
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Withdraw?',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kNavy)),
        content: Text('Are you sure you want to withdraw from "${t.name}"?',
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kNavy, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DatabaseService.instance.leaveTournament(uid, t.id);
      if (!mounted) return;
      setState(() => t.isJoined = false);
      _snack('Withdrawn from ${t.name}', isError: false);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to withdraw: $e', isError: true);
    }
  }

  void _shareTournament(Tournament t) {
    Clipboard.setData(ClipboardData(
        text: '🎾 ${t.name}\n📍 ${t.venue}\n📅 ${t.startDate} at ${t.startTime}\nJoin on CourtSync!'));
    _snack('Tournament link copied to clipboard!', isError: false);
  }

  void _showDetail(Tournament t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TournamentDetailSheet(
        tournament: t,
        onJoin: () { Navigator.pop(context); _joinTournament(t); },
        onWithdraw: () { Navigator.pop(context); _withdrawTournament(t); },
        onShare: () => _shareTournament(t),
      ),
    );
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? _kRed : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── Sliver AppBar ─────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _kNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Tournaments',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B2A), _kNavy],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 52),
                      child: Text(
                        '${_tournaments.length} tournaments available',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: _kGreen,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text('ALL (${_filtered.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text('MINE (${_myFiltered.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Filter bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterBar(
              selectedStatus: _statusFilter,
              selectedMatchType: _matchTypeFilter,
              onStatusChanged: (s) =>
                  setState(() => _statusFilter = s),
              onMatchTypeChanged: (m) =>
                  setState(() => _matchTypeFilter = m),
              onClearAll: () => setState(() {
                _statusFilter = null;
                _matchTypeFilter = null;
              }),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _TournamentList(
              tournaments: _filtered,
              onTap: _showDetail,
            ),
            _TournamentList(
              tournaments: _myFiltered,
              emptyMessage: 'You haven\'t joined or created any tournaments yet',
              onTap: _showDetail,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final TournamentStatus?    selectedStatus;
  final TournamentMatchType? selectedMatchType;
  final ValueChanged<TournamentStatus?>    onStatusChanged;
  final ValueChanged<TournamentMatchType?> onMatchTypeChanged;
  final VoidCallback onClearAll;

  const _FilterBar({
    required this.selectedStatus,
    required this.selectedMatchType,
    required this.onStatusChanged,
    required this.onMatchTypeChanged,
    required this.onClearAll,
  });

  bool get _hasFilter =>
      selectedStatus != null || selectedMatchType != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status filters
            ...TournamentStatus.values.map((s) => _FilterChip(
                  label: s.label,
                  icon: s.icon,
                  color: s.color,
                  selected: selectedStatus == s,
                  onTap: () => onStatusChanged(
                      selectedStatus == s ? null : s),
                )),

            Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 6)),

            // Match type filters
            ...TournamentMatchType.values.map((m) {
              final icons = {
                TournamentMatchType.singles: Icons.person_rounded,
                TournamentMatchType.doubles: Icons.people_rounded,
                TournamentMatchType.both:    Icons.groups_rounded,
              };
              return _FilterChip(
                label: m.label,
                icon: icons[m]!,
                color: _kNavy,
                selected: selectedMatchType == m,
                onTap: () => onMatchTypeChanged(
                    selectedMatchType == m ? null : m),
              );
            }),

            // Clear all
            if (_hasFilter) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClearAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _kRed.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.close_rounded,
                          color: _kRed, size: 13),
                      SizedBox(width: 4),
                      Text('Clear',
                          style: TextStyle(
                              color: _kRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? Colors.white : color, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT LIST
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentList extends StatelessWidget {
  final List<Tournament> tournaments;
  final String emptyMessage;
  final void Function(Tournament) onTap;

  const _TournamentList({
    required this.tournaments,
    this.emptyMessage = 'No tournaments match your filters',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: tournaments.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _TournamentCard(
            tournament: tournaments[i], onTap: () => onTap(tournaments[i])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOURNAMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final spotsPercent =
        t.spotsTotal == 0 ? 0.0 : (t.spotsTotal - t.spotsLeft) / t.spotsTotal;
    final isFull = t.spotsLeft == 0;

    Color spotsColor = _kGreen;
    if (t.spotsLeft <= 3 && t.spotsLeft > 0) spotsColor = Colors.orange;
    if (isFull) spotsColor = _kRed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // ── Image + overlay ─────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                  child: Image.asset(
                    t.imagePath,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: _kNavy.withOpacity(0.85),
                      child: const Center(
                        child: Icon(Icons.sports_tennis,
                            color: Colors.white, size: 44),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.status.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.status.icon,
                            color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text(t.status.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                // Joined badge
                if (t.isJoined)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              color: Colors.white, size: 11),
                          SizedBox(width: 4),
                          Text('Joined',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                // Name overlay bottom of image
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54)
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: _kBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(t.venue,
                            style: const TextStyle(
                                color: _kBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kNavy.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t.format.label,
                            style: const TextStyle(
                                color: _kNavy,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${t.startDate} · ${t.startTime}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                      const Spacer(),
                      const Icon(Icons.sports_tennis_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(t.matchType.label,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Spots progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: spotsPercent,
                            backgroundColor:
                                Colors.grey.shade100,
                            valueColor:
                                AlwaysStoppedAnimation(spotsColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isFull
                            ? 'Full'
                            : '${t.spotsLeft} spot${t.spotsLeft == 1 ? '' : 's'} left',
                        style: TextStyle(
                          color: spotsColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Footer bar ───────────────────────────────────────────────────
            const SizedBox(height: 10),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(18)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Fee
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.isFree
                          ? _kGreen.withOpacity(0.1)
                          : _kGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.isFree
                          ? 'Free Entry'
                          : '${t.entryFee!.toStringAsFixed(1)} OMR',
                      style: TextStyle(
                        color: t.isFree ? _kGreen : Colors.brown,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (t.prize != null)
                    Row(children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: _kGold, size: 13),
                      const SizedBox(width: 3),
                      Text('Prize',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11)),
                    ]),
                  const Spacer(),
                  // View details button
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Details',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentDetailSheet extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onJoin;
  final VoidCallback onWithdraw;
  final VoidCallback onShare;

  const _TournamentDetailSheet({
    required this.tournament,
    required this.onJoin,
    required this.onWithdraw,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final bool canJoin = !t.isJoined &&
        t.spotsLeft > 0 &&
        t.status == TournamentStatus.upcoming;
    final bool canWithdraw =
        t.isJoined && t.status == TournamentStatus.upcoming;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Image header
            Stack(
              children: [
                ClipRRect(
                  child: Image.asset(
                    t.imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: _kNavy,
                      child: const Center(
                        child: Icon(Icons.sports_tennis,
                            color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.status.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t.status.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      Text(t.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                    blurRadius: 6,
                                    color: Colors.black54)
                              ])),
                    ],
                  ),
                ),
                // Share button
                Positioned(
                  top: 10,
                  right: 12,
                  child: GestureDetector(
                    onTap: onShare,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(t.description,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.6)),
                  const SizedBox(height: 20),

                  // Info grid
                  _InfoGrid(tournament: t),
                  const SizedBox(height: 20),

                  // Spots bar
                  _SpotsSection(tournament: t),
                  const SizedBox(height: 20),

                  // Prize
                  if (t.prize != null) ...[
                    _DetailRow(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Prize',
                        value: t.prize!,
                        valueColor: Colors.brown.shade700),
                    const SizedBox(height: 20),
                  ],

                  // Action buttons
                  if (canJoin)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: onJoin,
                        icon: const Icon(Icons.sports_tennis_rounded,
                            size: 18),
                        label: Text(
                          t.isFree
                              ? 'Join — Free'
                              : 'Join — ${t.entryFee!.toStringAsFixed(1)} OMR',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),

                  if (t.isJoined && !canWithdraw)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _kGreen.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: _kGreen, size: 20),
                          SizedBox(width: 8),
                          Text('You\'re registered',
                              style: TextStyle(
                                  color: _kGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),

                  if (canWithdraw) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: onWithdraw,
                        icon: const Icon(
                            Icons.exit_to_app_rounded,
                            size: 18),
                        label: const Text('Withdraw from Tournament',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kRed),
                          foregroundColor: _kRed,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  if (t.spotsLeft == 0 && !t.isJoined)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: _kRed.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _kRed.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded,
                              color: _kRed, size: 18),
                          SizedBox(width: 8),
                          Text('Tournament Full',
                              style: TextStyle(
                                  color: _kRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO GRID
// ─────────────────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final Tournament tournament;
  const _InfoGrid({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Venue',
              value: '${t.venue}\n${t.location}',
              valueColor: _kBlue),
          _divider(),
          _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Dates',
              value: '${t.startDate} – ${t.endDate}'),
          _divider(),
          _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Start Time',
              value: t.startTime),
          _divider(),
          _DetailRow(
              icon: Icons.account_tree_rounded,
              label: 'Format',
              value: t.format.label),
          _divider(),
          _DetailRow(
              icon: Icons.sports_tennis_rounded,
              label: 'Match Type',
              value: t.matchType.label),
          _divider(),
          _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Entry Fee',
              value: t.isFree
                  ? 'Free'
                  : '${t.entryFee!.toStringAsFixed(1)} OMR',
              valueColor: t.isFree ? _kGreen : Colors.brown.shade700),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kNavy.withOpacity(0.6)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? _kNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPOTS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _SpotsSection extends StatelessWidget {
  final Tournament tournament;
  const _SpotsSection({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final filled = t.spotsTotal - t.spotsLeft;
    final pct = t.spotsTotal == 0 ? 0.0 : filled / t.spotsTotal;

    Color barColor = _kGreen;
    if (pct >= 0.9) barColor = _kRed;
    else if (pct >= 0.7) barColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Spots',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kNavy)),
            Text('$filled / ${t.spotsTotal} filled',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.spotsLeft == 0
              ? 'No spots remaining'
              : '${t.spotsLeft} spot${t.spotsLeft == 1 ? '' : 's'} remaining',
          style: TextStyle(
              color: barColor,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
