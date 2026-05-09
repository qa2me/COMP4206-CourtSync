import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy  = Color(0xFF1A2A4A);
const Color _kGreen = Color(0xFF4CAF50);
const Color _kBg    = Color(0xFFF4F6F9);
const Color _kRed   = Color(0xFFE53935);
const Color _kGold  = Color(0xFFFFD700);

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
enum TournamentFormat { singleElimination, doubleElimination, roundRobin, swiss }
enum MatchType { singles, doubles, both }
enum EntryFeeType { free, paid }

extension TournamentFormatExt on TournamentFormat {
  String get label {
    switch (this) {
      case TournamentFormat.singleElimination: return 'Single Elimination';
      case TournamentFormat.doubleElimination: return 'Double Elimination';
      case TournamentFormat.roundRobin:        return 'Round Robin';
      case TournamentFormat.swiss:             return 'Swiss';
    }
  }

  IconData get icon {
    switch (this) {
      case TournamentFormat.singleElimination: return Icons.account_tree_rounded;
      case TournamentFormat.doubleElimination: return Icons.device_hub_rounded;
      case TournamentFormat.roundRobin:        return Icons.loop_rounded;
      case TournamentFormat.swiss:             return Icons.swap_vert_rounded;
    }
  }

  String get description {
    switch (this) {
      case TournamentFormat.singleElimination: return 'One loss and you\'re out';
      case TournamentFormat.doubleElimination: return 'Two losses to be eliminated';
      case TournamentFormat.roundRobin:        return 'Everyone plays everyone';
      case TournamentFormat.swiss:             return 'Paired by performance each round';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});

  @override
  State<CreateTournamentPage> createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage>
    with SingleTickerProviderStateMixin {

  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _venueCtrl      = TextEditingController();
  final _locationCtrl   = TextEditingController();
  final _feeCtrl        = TextEditingController();
  final _prizeCtrl      = TextEditingController();
  final _maxPlayersCtrl = TextEditingController();

  TournamentFormat _format    = TournamentFormat.singleElimination;
  MatchType        _matchType = MatchType.singles;
  EntryFeeType     _feeType   = EntryFeeType.free;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;

  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // Section expand state
  final Map<int, bool> _expanded = {0: true, 1: false, 2: false, 3: false};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _locationCtrl.dispose();
    _feeCtrl.dispose();
    _prizeCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }

  // ── Date / Time pickers ────────────────────────────────────────────────────
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _kNavy,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: _kNavy,
        ),
      ),
      child: child!,
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    // Expand all sections to reveal errors
    setState(() => _expanded.updateAll((_, __) => true));
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      _snack('Please select a start date', isError: true); return;
    }
    if (_startTime == null) {
      _snack('Please select a start time', isError: true); return;
    }
    if (_endDate == null) {
      _snack('Please select an end date', isError: true); return;
    }

    setState(() => _isLoading = true);
    try {
      await DatabaseService.instance.createTournament({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'venue': _venueCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'startDate': '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
        'endDate': '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
        'startTime': _startTime!.format(context),
        'status': 'upcoming',
        'matchType': _matchType.name,
        'format': _format.name,
        'isFree': _feeType == EntryFeeType.free,
        'entryFee': _feeType == EntryFeeType.paid ? double.tryParse(_feeCtrl.text.trim()) : null,
        'prize': _prizeCtrl.text.trim(),
        'spotsTotal': int.tryParse(_maxPlayersCtrl.text.trim()) ?? 0,
        'spotsLeft': int.tryParse(_maxPlayersCtrl.text.trim()) ?? 0,
        'imagePath': 'assets/images/court1.png',
        'isCreatedByMe': true,
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to create tournament: $e', isError: true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tournament Created!', style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy)),
        content: const Text('Your tournament has been submitted for approval.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: _kNavy)),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kGold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pending_actions_rounded,
                  color: _kGold, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Submitted for Approval',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _kNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your tournament "${_nameCtrl.text}" has been submitted.\n\nAn admin will review it within 24–48 hours. You\'ll be notified once it\'s approved.',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Got it',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 130,
              backgroundColor: _kNavy,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                titlePadding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: const Text(
                  'Create Tournament',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1B2A), _kNavy],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _kGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kGold.withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pending_actions_rounded,
                                    color: _kGold, size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'Pending Approval',
                                  style: TextStyle(
                                      color: _kGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Form ─────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        // Section 1 — Basic Info
                        _Section(
                          index: 0,
                          title: 'Basic Information',
                          icon: Icons.info_outline_rounded,
                          expanded: _expanded[0]!,
                          onToggle: () => setState(
                              () => _expanded[0] = !_expanded[0]!),
                          child: Column(
                            children: [
                              _label('Tournament Name *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameCtrl,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    _req(v, 'Tournament name'),
                                decoration: _deco(
                                    hint: 'e.g. Muscat Open 2026',
                                    icon: Icons.emoji_events_rounded),
                              ),
                              const SizedBox(height: 16),

                              _label('Description *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _descCtrl,
                                maxLines: 3,
                                maxLength: 300,
                                validator: (v) =>
                                    _req(v, 'Description'),
                                decoration: _deco(
                                  hint:
                                      'Tell players what this tournament is about...',
                                  icon: Icons.description_outlined,
                                ).copyWith(
                                  prefixIcon: null,
                                  contentPadding:
                                      const EdgeInsets.all(14),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Section 2 — Format & Match Type
                        _Section(
                          index: 1,
                          title: 'Format & Match Type',
                          icon: Icons.sports_tennis_rounded,
                          expanded: _expanded[1]!,
                          onToggle: () => setState(
                              () => _expanded[1] = !_expanded[1]!),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Tournament Format *'),
                              const SizedBox(height: 10),

                              // Format grid
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.55,
                                children: TournamentFormat.values
                                    .map((f) => _FormatCard(
                                          format: f,
                                          selected: _format == f,
                                          onTap: () => setState(
                                              () => _format = f),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 20),

                              _label('Match Type *'),
                              const SizedBox(height: 10),

                              // Match type chips
                              Row(
                                children: MatchType.values.map((t) {
                                  final labels = {
                                    MatchType.singles: 'Singles',
                                    MatchType.doubles: 'Doubles',
                                    MatchType.both:    'Both',
                                  };
                                  final icons = {
                                    MatchType.singles: Icons.person_rounded,
                                    MatchType.doubles: Icons.people_rounded,
                                    MatchType.both: Icons.groups_rounded,
                                  };
                                  final selected = _matchType == t;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _matchType = t),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        margin: EdgeInsets.only(
                                            right: t != MatchType.both
                                                ? 8
                                                : 0),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? _kNavy
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selected
                                                ? _kNavy
                                                : const Color(
                                                    0xFFE0E4EC),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(icons[t],
                                                color: selected
                                                    ? Colors.white
                                                    : Colors
                                                        .grey.shade500,
                                                size: 20),
                                            const SizedBox(height: 4),
                                            Text(
                                              labels[t]!,
                                              style: TextStyle(
                                                color: selected
                                                    ? Colors.white
                                                    : Colors
                                                        .grey.shade600,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Section 3 — Venue & Date
                        _Section(
                          index: 2,
                          title: 'Venue & Schedule',
                          icon: Icons.location_on_rounded,
                          expanded: _expanded[2]!,
                          onToggle: () => setState(
                              () => _expanded[2] = !_expanded[2]!),
                          child: Column(
                            children: [
                              _label('Venue Name *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _venueCtrl,
                                textInputAction: TextInputAction.next,
                                validator: (v) => _req(v, 'Venue'),
                                decoration: _deco(
                                    hint:
                                        'e.g. Muscat Tennis Complex',
                                    icon: Icons.stadium_rounded),
                              ),
                              const SizedBox(height: 16),

                              _label('Full Address *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _locationCtrl,
                                textInputAction: TextInputAction.next,
                                validator: (v) => _req(v, 'Address'),
                                decoration: _deco(
                                    hint:
                                        'Street, city, governorate',
                                    icon: Icons.map_outlined),
                              ),
                              const SizedBox(height: 20),

                              // Date row
                              Row(
                                children: [
                                  Expanded(
                                    child: _DatePickerTile(
                                      label: 'Start Date *',
                                      icon: Icons.calendar_today_rounded,
                                      value: _startDate == null
                                          ? null
                                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                      placeholder: 'Select date',
                                      onTap: _pickStartDate,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _DatePickerTile(
                                      label: 'Start Time *',
                                      icon: Icons.access_time_rounded,
                                      value: _startTime == null
                                          ? null
                                          : _startTime!.format(context),
                                      placeholder: 'Select time',
                                      onTap: _pickStartTime,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _DatePickerTile(
                                label: 'End Date *',
                                icon: Icons.event_rounded,
                                value: _endDate == null
                                    ? null
                                    : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                placeholder: 'Select end date',
                                onTap: _pickEndDate,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Section 4 — Players, Fees, Prize
                        _Section(
                          index: 3,
                          title: 'Players, Entry & Prize',
                          icon: Icons.monetization_on_outlined,
                          expanded: _expanded[3]!,
                          onToggle: () => setState(
                              () => _expanded[3] = !_expanded[3]!),
                          child: Column(
                            children: [
                              _label('Max Players / Spots *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _maxPlayersCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Required';
                                  final n = int.tryParse(v);
                                  if (n == null || n < 2)
                                    return 'Minimum 2 players';
                                  if (n > 256)
                                    return 'Maximum 256 players';
                                  return null;
                                },
                                decoration: _deco(
                                    hint: 'e.g. 16, 32, 64',
                                    icon: Icons.group_rounded),
                              ),
                              const SizedBox(height: 20),

                              // Entry fee toggle
                              _label('Entry Fee'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ToggleTile(
                                      label: 'Free Entry',
                                      icon: Icons.card_giftcard_rounded,
                                      selected: _feeType ==
                                          EntryFeeType.free,
                                      onTap: () => setState(() =>
                                          _feeType = EntryFeeType.free),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ToggleTile(
                                      label: 'Paid Entry',
                                      icon: Icons.payments_outlined,
                                      selected: _feeType ==
                                          EntryFeeType.paid,
                                      onTap: () => setState(() =>
                                          _feeType = EntryFeeType.paid),
                                    ),
                                  ),
                                ],
                              ),

                              // Fee amount — shown only if paid
                              if (_feeType == EntryFeeType.paid) ...[
                                const SizedBox(height: 14),
                                _label('Fee Amount (OMR) *'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _feeCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'))
                                  ],
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (_feeType == EntryFeeType.free)
                                      return null;
                                    if (v == null || v.isEmpty)
                                      return 'Enter fee amount';
                                    final n = double.tryParse(v);
                                    if (n == null || n <= 0)
                                      return 'Enter a valid amount';
                                    return null;
                                  },
                                  decoration: _deco(
                                      hint: '0.00',
                                      icon:
                                          Icons.attach_money_rounded),
                                ),
                              ],

                              const SizedBox(height: 20),

                              _label('Prize / Reward Info'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _prizeCtrl,
                                maxLines: 2,
                                decoration: _deco(
                                  hint:
                                      'e.g. Trophy + 500 OMR cash prize for winner',
                                  icon: Icons.workspace_premium_rounded,
                                ).copyWith(
                                  prefixIcon: null,
                                  contentPadding:
                                      const EdgeInsets.all(14),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kGold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _kGold.withOpacity(0.35)),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                  Icons.info_outline_rounded,
                                  color: _kGold,
                                  size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your tournament will be reviewed by an admin before it goes live. This usually takes 24–48 hours.',
                                  style: TextStyle(
                                    color: Colors.brown.shade700,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons
                                              .send_rounded,
                                          size: 18),
                                      SizedBox(width: 10),
                                      Text(
                                        'Submit for Approval',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String? _req(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _kNavy,
          ),
        ),
      );

  InputDecoration _deco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLLAPSIBLE SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _Section({
    required this.index,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: _kNavy, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _kNavy,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FormatCard extends StatelessWidget {
  final TournamentFormat format;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _kNavy : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kNavy : const Color(0xFFE0E4EC),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(format.icon,
                color: selected ? _kGreen : Colors.grey.shade400,
                size: 22),
            const SizedBox(height: 6),
            Text(
              format.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: selected ? Colors.white : _kNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              format.description,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? Colors.white.withOpacity(0.6)
                    : Colors.grey.shade500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE PICKER TILE
// ─────────────────────────────────────────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kNavy)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: hasValue
                  ? _kNavy.withOpacity(0.04)
                  : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue
                    ? _kNavy.withOpacity(0.4)
                    : const Color(0xFFE8EAF0),
                width: hasValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color:
                        hasValue ? _kNavy : Colors.grey.shade400,
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      color: hasValue
                          ? _kNavy
                          : Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE TILE (Free / Paid)
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kNavy : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? _kNavy : const Color(0xFFE0E4EC),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    selected ? _kGreen : Colors.grey.shade400,
                size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? Colors.white : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
