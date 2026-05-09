import 'package:flutter/material.dart';
import 'matches.dart';
import '../services/database_service.dart';

const Color _kNavy  = Color(0xFF1A2A4A);
const Color _kBlue  = Color(0xFF1565C0);
const Color _kRed   = Color(0xFFC62828);
const Color _kGreen = Color(0xFF2E7D32);

const List<String> _kPoints = ['0', '15', '30', '40', 'Game'];

enum _ActionType { point, fault }

class _Action {
  final _ActionType type;
  final int team;
  final Map<String, dynamic> snapshot;

  _Action({required this.type, required this.team, required this.snapshot});
}

class SimulateMatchPage extends StatefulWidget {
  final Match match;

  const SimulateMatchPage({super.key, required this.match});

  @override
  State<SimulateMatchPage> createState() => _SimulateMatchPageState();
}

class _SimulateMatchPageState extends State<SimulateMatchPage>
    with TickerProviderStateMixin {
  bool _matchStarted = false;

  int _bluePoints = 0;
  int _redPoints  = 0;
  int _blueGames  = 0;
  int _redGames   = 0;
  int _blueSets   = 0;
  int _redSets    = 0;

  int _faultCount = 0;
  int _servingTeam = 0;

  bool _isDeuce = false;
  int _deuceAdvantage = -1;

  final List<_Action> _history = [];

  late AnimationController _flashController;
  late Animation<double> _flashAnim;
  int _flashTeam = -1;

  String? _matchWinner;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _snapshot() => {
        'bluePoints': _bluePoints,
        'redPoints': _redPoints,
        'blueGames': _blueGames,
        'redGames': _redGames,
        'blueSets': _blueSets,
        'redSets': _redSets,
        'faultCount': _faultCount,
        'servingTeam': _servingTeam,
        'isDeuce': _isDeuce,
        'deuceAdvantage': _deuceAdvantage,
      };

  void _restoreSnapshot(Map<String, dynamic> s) {
    _bluePoints     = s['bluePoints'];
    _redPoints      = s['redPoints'];
    _blueGames      = s['blueGames'];
    _redGames       = s['redGames'];
    _blueSets       = s['blueSets'];
    _redSets        = s['redSets'];
    _faultCount     = s['faultCount'];
    _servingTeam    = s['servingTeam'];
    _isDeuce        = s['isDeuce'];
    _deuceAdvantage = s['deuceAdvantage'];
  }

  void _onHalfTapped(int scoringTeam) {
    if (!_matchStarted || _matchWinner != null) return;

    final before = _snapshot();

    setState(() {
      _faultCount = 0;

      if (_isDeuce) {
        if (_deuceAdvantage == -1) {
          _deuceAdvantage = scoringTeam;
        } else if (_deuceAdvantage == scoringTeam) {
          _isDeuce = false;
          _deuceAdvantage = -1;
          _awardGame(scoringTeam);
        } else {
          _deuceAdvantage = -1;
        }
      } else {
        if (scoringTeam == 0) {
          _bluePoints++;
        } else {
          _redPoints++;
        }

        if (_bluePoints == 3 && _redPoints == 3) {
          _isDeuce = true;
        } else if (_bluePoints >= 4) {
          _bluePoints = 0;
          _redPoints  = 0;
          _awardGame(0);
        } else if (_redPoints >= 4) {
          _bluePoints = 0;
          _redPoints  = 0;
          _awardGame(1);
        }
      }
    });

    _history.add(_Action(type: _ActionType.point, team: scoringTeam, snapshot: before));
    _flash(scoringTeam);
  }

  void _awardGame(int team) {
    if (team == 0) {
      _blueGames++;
    } else {
      _redGames++;
    }
    _servingTeam = 1 - _servingTeam;

    if (_blueGames >= 6 && _blueGames - _redGames >= 2) {
      _blueSets++;
      _blueGames = 0;
      _redGames  = 0;
      _checkMatchWinner();
    } else if (_redGames >= 6 && _redGames - _blueGames >= 2) {
      _redSets++;
      _blueGames = 0;
      _redGames  = 0;
      _checkMatchWinner();
    } else if (_blueGames == 7 || _redGames == 7) {
      if (_blueGames == 7) _blueSets++;
      else _redSets++;
      _blueGames = 0;
      _redGames  = 0;
      _checkMatchWinner();
    }
  }

  void _checkMatchWinner() {
    if (_blueSets == 2) _matchWinner = widget.match.player1.name;
    if (_redSets  == 2) _matchWinner = widget.match.player2.name;
  }

  Future<void> _finishMatch() async {
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.pop(context);
      return;
    }

    final profile = await DatabaseService.instance.userProfileStream(uid).first;
    if (profile == null) {
      Navigator.pop(context);
      return;
    }

    final currentPlayed = (profile['matchesPlayed'] ?? 0) as int;
    final currentWon    = (profile['matchesWon'] ?? 0) as int;
    final currentStreak = (profile['winStreak'] ?? 0) as int;

    final userWon = _matchWinner == widget.match.player1.name;

    await DatabaseService.instance.updateUserProfile(uid, {
      'matchesPlayed': currentPlayed + 1,
      'matchesWon': userWon ? currentWon + 1 : currentWon,
      'winStreak': userWon ? currentStreak + 1 : 0,
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _onFault() {
    if (!_matchStarted || _matchWinner != null) return;

    final before = _snapshot();

    setState(() {
      _faultCount++;
      if (_faultCount >= 2) {
        _faultCount = 0;
        _onHalfTapped(1 - _servingTeam);
        return;
      }
    });

    _history.add(_Action(type: _ActionType.fault, team: _servingTeam, snapshot: before));

    if (_faultCount == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('First fault! One more = double fault (point lost)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    setState(() {
      _restoreSnapshot(last.snapshot);
      _matchWinner = null;
    });
  }

  void _flash(int team) {
    setState(() => _flashTeam = team);
    _flashController.forward(from: 0).then((_) {
      setState(() => _flashTeam = -1);
    });
  }

  String get _bluePointLabel =>
      _isDeuce
          ? (_deuceAdvantage == 0 ? 'ADV' : 'DEUCE')
          : _kPoints[_bluePoints.clamp(0, 4)];

  String get _redPointLabel =>
      _isDeuce
          ? (_deuceAdvantage == 1 ? 'ADV' : 'DEUCE')
          : _kPoints[_redPoints.clamp(0, 4)];

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A2A),
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${widget.match.player1.name.replaceAll('\n', '/')} vs ${widget.match.player2.name.replaceAll('\n', '/')}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_matchStarted && _history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'Undo last action',
              onPressed: _undo,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreBoard(),
          Expanded(child: _buildPlayArea()),
          if (_matchStarted) _buildFaultBar(),
          if (_matchStarted) _buildServeIndicator(),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(child: _ScoreColumn(
            name: widget.match.player1.name.replaceAll('\n', '\n'),
            sets: _blueSets,
            games: _blueGames,
            points: _bluePointLabel,
            color: _kBlue,
            isServing: _matchStarted && _servingTeam == 0,
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('VS',
                style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          Expanded(child: _ScoreColumn(
            name: widget.match.player2.name.replaceAll('\n', '\n'),
            sets: _redSets,
            games: _redGames,
            points: _redPointLabel,
            color: _kRed,
            isServing: _matchStarted && _servingTeam == 1,
            alignRight: true,
          )),
        ],
      ),
    );
  }

  Widget _buildPlayArea() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Column(
            children: [
              // Blue square
              Expanded(
                child: GestureDetector(
                  onTap: () => _onHalfTapped(0),
                  child: AnimatedBuilder(
                    animation: _flashAnim,
                    builder: (_, __) {
                      final flashColor = _flashTeam == 0
                          ? Color.lerp(_kBlue, Colors.white, _flashAnim.value)!
                          : _kBlue;
                      return Container(
                        color: flashColor,
                        child: Center(
                          child: Text(
                            widget.match.player1.name.replaceAll('\n', ' & '),
                            style: TextStyle(
                              color: _matchStarted
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white38,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Start button divider
              Container(
                height: 48,
                color: _kNavy,
                child: Center(
                  child: _matchStarted
                      ? Text(
                          'Match in progress',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        )
                      : SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _matchStarted = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 20),
                                SizedBox(width: 6),
                                Text('Start Match',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              // Red square
              Expanded(
                child: GestureDetector(
                  onTap: () => _onHalfTapped(1),
                  child: AnimatedBuilder(
                    animation: _flashAnim,
                    builder: (_, __) {
                      final flashColor = _flashTeam == 1
                          ? Color.lerp(_kRed, Colors.white, _flashAnim.value)!
                          : _kRed;
                      return Container(
                        color: flashColor,
                        child: Center(
                          child: Text(
                            widget.match.player2.name.replaceAll('\n', ' & '),
                            style: TextStyle(
                              color: _matchStarted
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white38,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Winner overlay
          if (_matchWinner != null)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Color(0xFFF9A825), size: 48),
                      const SizedBox(height: 12),
                      const Text('Match Winner!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _kNavy)),
                      const SizedBox(height: 8),
                      Text(
                        _matchWinner!.replaceAll('\n', ' & '),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kGreen),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_blueSets – $_redSets',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _kNavy),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _finishMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Finish Match',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildFaultBar() {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FAULTS',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(2, (i) {
                  final active = i < _faultCount;
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Colors.orange : Colors.white24,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _matchWinner == null ? _onFault : null,
              icon: const Icon(Icons.warning_amber_rounded, size: 16),
              label: const Text('Fault',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _history.isNotEmpty ? _undo : null,
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('Undo',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white30,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServeIndicator() {
    final name = _servingTeam == 0
        ? widget.match.player1.name.replaceAll('\n', ' & ')
        : widget.match.player2.name.replaceAll('\n', ' & ');
    final color = _servingTeam == 0 ? _kBlue : _kRed;

    return Container(
      color: _kNavy.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            'Serving: $name',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Score Column ──────────────────────────────────────────────────────────────

class _ScoreColumn extends StatelessWidget {
  final String name;
  final int sets;
  final int games;
  final String points;
  final Color color;
  final bool isServing;
  final bool alignRight;

  const _ScoreColumn({
    required this.name,
    required this.sets,
    required this.games,
    required this.points,
    required this.color,
    required this.isServing,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignRight && isServing)
              Container(
                margin: const EdgeInsets.only(right: 6),
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alignRight && isServing)
              Container(
                margin: const EdgeInsets.only(left: 6),
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment:
              alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            _ScorePill(label: 'SET', value: '$sets', color: color),
            const SizedBox(width: 6),
            _ScorePill(label: 'GAME', value: '$games', color: color),
            const SizedBox(width: 6),
            _ScorePill(label: 'PT', value: points, color: color, big: true),
          ],
        ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool big;

  const _ScorePill({
    required this.label,
    required this.value,
    required this.color,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: big ? 10 : 8, vertical: big ? 4 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: big ? 16 : 14,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
