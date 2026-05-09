import 'package:flutter/material.dart';
import 'matches.dart';
import 'simulate_match_page.dart';
import '../services/database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy   = Color(0xFF1A2A4A);
const Color _kBlue   = Color(0xFF2196F3);
const Color _kGreen  = Color(0xFF4CAF50);
const Color _kBg     = Color(0xFFF4F6F9);

// ─────────────────────────────────────────────────────────────────────────────
// START MATCH PAGE
// ─────────────────────────────────────────────────────────────────────────────
class StartMatchPage extends StatefulWidget {
  const StartMatchPage({super.key});

  @override
  State<StartMatchPage> createState() => _StartMatchPageState();
}

class _StartMatchPageState extends State<StartMatchPage> {
  // ── Step tracking ──────────────────────────────────────────────────────────
  int _step = 0;
  int get _totalSteps => _isPrivate == false ? 5 : 3;
  List<String> get _stepLabels {
    if (_isPrivate == true) {
      return ['Visibility', 'Type', 'Players', 'Referee'];
    }
    return ['Visibility', 'Type', 'Players', 'Referee', 'Studio', 'Payment'];
  }

  // ── Choices ────────────────────────────────────────────────────────────────
  bool? _isPrivate;           // true=Private, false=Public
  bool? _isDoubles;           // true=Doubles, false=Single

  // ── Controllers ───────────────────────────────────────────────────────────
  final _p1Controller  = TextEditingController();
  final _p2Controller  = TextEditingController(); // doubles only
  final _op1Controller = TextEditingController(); // opponent 1
  final _op2Controller = TextEditingController(); // opponent 2 (doubles)
  final _refController = TextEditingController();
  final _studioController = TextEditingController();
  final _feeController = TextEditingController();
  bool _hasReferee = false;
  bool _isJoinable = false;

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    _op1Controller.dispose();
    _op2Controller.dispose();
    _refController.dispose();
    _studioController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  Future<void> _next() async {
    if (_step >= _totalSteps) {
      await _startMatch();
    } else {
      setState(() => _step++);
    }
  }
  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  // ── Build match & navigate ─────────────────────────────────────────────────
  Future<void> _startMatch() async {
    final isPublic = _isPrivate == false;
    final isSingles = _isDoubles == false;

    final joinable = _isJoinable && isPublic;
    final p1Raw = _p1Controller.text.trim();
    final p2Raw = _p2Controller.text.trim();
    final op1Raw = _op1Controller.text.trim();
    final op2Raw = _op2Controller.text.trim();

    // For public joinable matches, empty slots become "Empty..." for others to fill
    String player1Name;
    String player2Name;
    int joinedPlayers;
    if (isSingles) {
      final hasP1 = p1Raw.isNotEmpty;
      final hasOp = op1Raw.isNotEmpty;
      if (joinable && !hasP1 && !hasOp) {
        player1Name = 'Empty...';
        player2Name = 'Empty...';
        joinedPlayers = 0;
      } else {
        player1Name = hasP1 ? p1Raw : 'Empty...';
        player2Name = hasOp ? op1Raw : 'Empty...';
        joinedPlayers = (hasP1 ? 1 : 0) + (hasOp ? 1 : 0);
      }
    } else {
      final hasP1 = p1Raw.isNotEmpty;
      final hasP2 = p2Raw.isNotEmpty;
      final hasOp1 = op1Raw.isNotEmpty;
      final hasOp2 = op2Raw.isNotEmpty;
      if (joinable && !hasP1 && !hasP2 && !hasOp1 && !hasOp2) {
        player1Name = 'Empty...\nEmpty...';
        player2Name = 'Empty...\nEmpty...';
        joinedPlayers = 0;
      } else {
        player1Name = '${hasP1 ? p1Raw : 'Empty...'}\n${hasP2 ? p2Raw : 'Empty...'}';
        player2Name = '${hasOp1 ? op1Raw : 'Empty...'}\n${hasOp2 ? op2Raw : 'Empty...'}';
        joinedPlayers = (hasP1 ? 1 : 0) + (hasP2 ? 1 : 0) + (hasOp1 ? 1 : 0) + (hasOp2 ? 1 : 0);
      }
    }

    final totalPlayers = isSingles ? 2 : 4;

    final venue = isPublic
        ? _studioController.text.trim()
        : 'Private Court';
    final feeText = _feeController.text.trim();
    final fee = double.tryParse(feeText);
    final hasReferee = _hasReferee && _refController.text.trim().isNotEmpty;

    final match = Match(
      player1: MatchPlayer(name: player1Name),
      player2: MatchPlayer(name: player2Name),
      venue: venue.isEmpty ? 'TBD' : venue,
      type: _isDoubles == true
          ? 'Friendly match - Doubles'
          : 'Friendly match - Single',
      dateTime:
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - '
          '${TimeOfDay.now().format(context)}',
      playersJoined: joinedPlayers,
      playersTotal: totalPlayers,
      isManager: false,
      referee: hasReferee ? _refController.text.trim() : null,
      isPublic: isPublic,
      entryFee: fee,
      studioName: venue,
    );

    final matchData = {
      'player1Name': player1Name.isNotEmpty ? player1Name : 'Player 1',
      'player2Name': player2Name.isNotEmpty ? player2Name : (isSingles ? 'Player 2' : 'Partner'),
      'venue': venue,
      'type': _isDoubles == true
          ? 'Friendly match - Doubles'
          : 'Friendly match - Single',
      'dateTime': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - ${TimeOfDay.now().format(context)}',
      'playersJoined': joinedPlayers,
      'playersTotal': totalPlayers,
      'isManager': false,
      'referee': hasReferee ? _refController.text.trim() : null,
      'isPublic': isPublic,
      'entryFee': fee,
      'studioName': venue,
    };

    String? matchId;
    try {
      matchId = await DatabaseService.instance.createMatch(matchData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create match: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Only auto-add creator if they entered their own name (not an open slot)
    final uid = DatabaseService.instance.currentUser?.uid;
    final creatorPlayed = !player1Name.contains('Empty...');
    if (uid != null && matchId != null && creatorPlayed) {
      await DatabaseService.instance.addUserMatch(uid, matchId, {
        'role': 'Player',
        'joinedAt': DateTime.now().toIso8601String(),
        'matchData': matchData,
      });
    }

    if (!isPublic) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimulateMatchPage(match: match),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(joinable ? 'Public match created! Others can join.' : 'Match added for referee signup.'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Start a Match',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final steps = _stepLabels;
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i <= _step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? _kBlue : Colors.white24,
                        border: Border.all(
                          color: active ? _kBlue : Colors.white38,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: i < _step
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active ? Colors.white : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: i < _step ? _kBlue : Colors.white24,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step router ───────────────────────────────────────────────────────────
  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildVisibilityStep();
      case 1:
        return _buildTypeStep();
      case 2:
        return _buildPlayersStep();
      case 3:
        return _buildRefereeStep();
      case 4:
        return _buildStudioStep();
      case 5:
        return _buildPaymentStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Visibility ────────────────────────────────────────────────────
  Widget _buildVisibilityStep() {
    return _StepCard(
      icon: Icons.lock_outline_rounded,
      title: 'Match Visibility',
      subtitle: 'Who can join this match?',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ChoiceTile(
            icon: Icons.lock_rounded,
            title: 'Private',
            subtitle: 'Only invited players can join',
            selected: _isPrivate == true,
            onTap: () => setState(() => _isPrivate = true),
          ),
          const SizedBox(height: 12),
          _ChoiceTile(
            icon: Icons.public_rounded,
            title: 'Public',
            subtitle: 'Anyone can find and join',
            selected: _isPrivate == false,
            onTap: () => setState(() => _isPrivate = false),
          ),
          const SizedBox(height: 24),
          _NextButton(
            enabled: _isPrivate != null,
            onTap: _next,
          ),
        ],
      ),
    );
  }

  // ── Step 1: Match Type ────────────────────────────────────────────────────
  Widget _buildTypeStep() {
    return _StepCard(
      icon: Icons.sports_tennis_rounded,
      title: 'Match Type',
      subtitle: 'Singles or doubles?',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ChoiceTile(
            icon: Icons.person_rounded,
            title: 'Single',
            subtitle: '1 vs 1 — head to head',
            selected: _isDoubles == false,
            onTap: () => setState(() => _isDoubles = false),
          ),
          const SizedBox(height: 12),
          _ChoiceTile(
            icon: Icons.group_rounded,
            title: 'Doubles',
            subtitle: '2 vs 2 — team play',
            selected: _isDoubles == true,
            onTap: () => setState(() => _isDoubles = true),
          ),
          const SizedBox(height: 24),
          _NextButton(
            enabled: _isDoubles != null,
            onTap: _next,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Players ───────────────────────────────────────────────────────
  Widget _buildPlayersStep() {
    final isDoubles = _isDoubles == true;
    final isPublic = _isPrivate == false;
    return _StepCard(
      icon: Icons.group_rounded,
      title: 'Player Usernames',
      subtitle: isPublic
          ? 'Leave fields empty to open slots for others to join'
          : isDoubles
              ? 'Enter all 4 players\' usernames'
              : 'Enter both players\' usernames',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Team A
          _TeamLabel(label: 'Team A', color: _kBlue),
          const SizedBox(height: 8),
          _UsernameField(
            controller: _p1Controller,
            label: isDoubles ? 'Player 1' : 'Your Username${isPublic ? ' (optional)' : ''}',
            icon: Icons.person_rounded,
            onChanged: (_) => setState(() {}),
          ),
          if (isDoubles) ...[
            const SizedBox(height: 10),
            _UsernameField(
              controller: _p2Controller,
              label: 'Player 2${isPublic ? ' (optional)' : ''}',
              icon: Icons.person_rounded,
              onChanged: (_) => setState(() {}),
            ),
          ],

          const SizedBox(height: 16),

          // Team B
          _TeamLabel(label: 'Team B', color: Colors.red.shade400),
          const SizedBox(height: 8),
          _UsernameField(
            controller: _op1Controller,
            label: isDoubles ? 'Opponent 1 (optional)' : 'Opponent Username${isPublic ? ' (optional)' : ''}',
            icon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          if (isDoubles) ...[
            const SizedBox(height: 10),
            _UsernameField(
              controller: _op2Controller,
              label: 'Opponent 2 (optional)',
              icon: Icons.person_outline_rounded,
              onChanged: (_) => setState(() {}),
            ),
          ],

          const SizedBox(height: 24),
          _NextButton(
            enabled: _isPrivate != false
                ? _p1Controller.text.trim().isNotEmpty &&
                    _op1Controller.text.trim().isNotEmpty &&
                    (!isDoubles ||
                        (_p2Controller.text.trim().isNotEmpty &&
                            _op2Controller.text.trim().isNotEmpty))
                : true,
            onTap: _next,
            label: 'Continue',
          ),
        ],
      ),
    );
  }

  // ── Step 3: Referee ───────────────────────────────────────────────────────
  Widget _buildRefereeStep() {
    return _StepCard(
      icon: Icons.sports_rounded,
      title: 'Referee',
      subtitle: 'Do you have a referee for this match?',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ChoiceTile(
            icon: Icons.sports_rounded,
            title: 'Yes, I have a referee',
            subtitle: 'Enter their username below',
            selected: _hasReferee,
            onTap: () => setState(() => _hasReferee = true),
          ),
          const SizedBox(height: 12),
          _ChoiceTile(
            icon: Icons.sports_tennis_rounded,
            title: 'No referee',
            subtitle: 'Play without a referee',
            selected: !_hasReferee,
            onTap: () => setState(() => _hasReferee = false),
          ),
          if (_hasReferee) ...[
            const SizedBox(height: 16),
            _UsernameField(
              controller: _refController,
              label: 'Referee Username',
              icon: Icons.sports_rounded,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          _NextButton(
            enabled: !_hasReferee ||
                _refController.text.trim().isNotEmpty,
            onTap: _isPrivate == true ? _startMatch : _next,
            label: _isPrivate == true ? 'Start Match' : 'Continue',
            color: _isPrivate == true ? _kGreen : _kNavy,
          ),
        ],
      ),
    );
  }

  // ── Step 4: Studio / Court (public only) ──────────────────────────────────
  Widget _buildStudioStep() {
    return _StepCard(
      icon: Icons.location_on_rounded,
      title: 'Studio / Court',
      subtitle: 'Where will the match take place?',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _UsernameField(
            controller: _studioController,
            label: 'Studio or Court Name',
            icon: Icons.location_on_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          _NextButton(
            enabled: _studioController.text.trim().isNotEmpty,
            onTap: _next,
            label: 'Continue',
          ),
        ],
      ),
    );
  }

  // ── Step 5: Payment + Publish options (public only) ──────────────────────
  Widget _buildPaymentStep() {
    return _StepCard(
      icon: Icons.payment_rounded,
      title: 'Entry Fee',
      subtitle: 'Set the entry fee for this match (optional)',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _UsernameField(
            controller: _feeController,
            label: 'Entry Fee (OMR) — leave empty for free',
            icon: Icons.monetization_on_rounded,
          ),
          const SizedBox(height: 16),
          // Joinable toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isJoinable ? _kNavy : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isJoinable ? _kNavy : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: () => setState(() => _isJoinable = !_isJoinable),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Icon(
                    _isJoinable ? Icons.group_add_rounded : Icons.group_rounded,
                    color: _isJoinable ? Colors.white : _kNavy,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open for players to join',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _isJoinable ? Colors.white : _kNavy,
                          ),
                        ),
                        Text(
                          _isJoinable
                              ? 'Others can join as opponents'
                              : 'Match is closed — only entered players',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isJoinable
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isJoinable)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _NextButton(
            enabled: true,
            onTap: _startMatch,
            label: 'Publish Match',
            color: _kGreen,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kNavy, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kNavy)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kNavy : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kNavy : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : _kNavy, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: selected ? Colors.white : _kNavy)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white70
                              : Colors.grey.shade500)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const _UsernameField({
    required this.controller,
    required this.label,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: _kNavy, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kNavy, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _TeamLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color)),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  final Color color;

  const _NextButton({
    required this.enabled,
    required this.onTap,
    this.label = 'Next',
    this.color = _kNavy,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}
