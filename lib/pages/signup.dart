import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_dart/firebase_dart.dart';
import '../services/database_service.dart';
import '../widgets/headerAnfooter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy   = Color(0xFF1A2A4A);
const Color _kGreen  = Color(0xFF4CAF50);
const Color _kBg     = Color(0xFFF4F6F9);
const Color _kRed    = Color(0xFFE53935);
const Color _kGold   = Color(0xFFFFD700);

// ─────────────────────────────────────────────────────────────────────────────
// SIGN-UP PAGE
// ─────────────────────────────────────────────────────────────────────────────
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _firstNameCtrl    = TextEditingController();
  final _lastNameCtrl     = TextEditingController();
  final _emailCtrl        = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _confirmPassCtrl  = TextEditingController();
  final _bioCtrl          = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms            = false;
  bool _receiveNotifications   = true;
  bool _isLoading              = false;

  // Dropdown
  String? _selectedLevel;
  final List<String> _levels = [
    'Beginner', 'Intermediate', 'Advanced', 'Professional',
  ];

  // Radio — play style
  String _playStyle = 'Singles';
  final List<String> _playStyles = ['Singles', 'Doubles', 'Both'];

  // Slider — hours per week
  double _hoursPerWeek = 5;

  // CV PDF
  String? _cvFileName;
  String? _cvFilePath;
  String? _cvError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Step tracking
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────────────────────
  String? _required(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[\d\s\-]{8,15}$').hasMatch(v.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8)           return 'At least 8 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  String? _validateLevel(String? v) {
    if (v == null) return 'Please select your skill level';
    return null;
  }

  // ── CV Picker ───────────────────────────────────────────────────────────────
  Future<void> _pickCV() async {
    setState(() => _cvError = null);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Validate — PDF only (double-check extension)
      if (file.extension?.toLowerCase() != 'pdf') {
        setState(() => _cvError = 'Only PDF files are accepted');
        return;
      }

      // Validate — max 5 MB
      if ((file.size) > 5 * 1024 * 1024) {
        setState(() => _cvError = 'File must be under 5 MB');
        return;
      }

      setState(() {
        _cvFileName = file.name;
        _cvFilePath = file.path;
        _cvError    = null;
      });
    } catch (e) {
      setState(() => _cvError = 'Failed to pick file. Please try again.');
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (_cvFilePath == null) {
      setState(() => _cvError = 'Please upload your CV as a PDF');
    }
    if (!_formKey.currentState!.validate()) return;
    if (_cvFilePath == null) return;
    if (!_acceptTerms) {
      _showFeedback('Please accept the terms and conditions', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await DatabaseService.instance.signUp(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      await DatabaseService.instance.createUser(cred.user!.uid, {
        'email': _emailCtrl.text.trim(),
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skillLevel': _selectedLevel ?? '',
        'playStyle': _playStyle,
        'hoursPerWeek': _hoursPerWeek.round(),
        'receiveNotifications': _receiveNotifications,
        'utr': '0.0',
        'rank': 0,
        'matchesPlayed': 0,
        'matchesWon': 0,
        'winStreak': 0,
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
      });
      if (!mounted) return;
      _showFeedback('Account created successfully!', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HeaderAndFooter()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showFeedback(e.message ?? 'Sign up failed', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showFeedback('$e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedback(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError ? _kRed : _kGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Header gradient
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B2A), _kNavy],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  // ── Top bar ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            'Step ${_currentStep + 1} of 2',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Header text ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Join the CourtSync community',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Step indicator
                          _StepIndicator(current: _currentStep),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // ── Form card ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Step 1
                              if (_currentStep == 0) _buildStep1(),
                              // Step 2
                              if (_currentStep == 1) _buildStep2(),

                              // Navigation buttons
                              _buildNavButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sign-in link
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: _kNavy,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
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

  // ── STEP 1: Personal info ──────────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information',
              icon: Icons.person_rounded),
          const SizedBox(height: 20),

          // First + Last name row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('First Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'First name'),
                      decoration: _inputDeco(
                          hint: 'Ahmed',
                          icon: Icons.badge_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Last Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'Last name'),
                      decoration: _inputDeco(
                          hint: 'Al-Rawahi',
                          icon: Icons.badge_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _label('Email Address'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            decoration: _inputDeco(
                hint: 'you@example.com',
                icon: Icons.email_outlined),
          ),
          const SizedBox(height: 16),

          // Phone
          _label('Phone Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-]'))
            ],
            validator: _validatePhone,
            decoration: _inputDeco(
                hint: '+968 9X XXX XXX',
                icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 16),

          // Password
          _label('Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            decoration: _inputDeco(
              hint: 'Min 8 chars, 1 uppercase, 1 number',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          // Password strength hint
          const SizedBox(height: 6),
          _PasswordStrengthBar(password: _passwordCtrl.text),
          const SizedBox(height: 16),

          // Confirm Password
          _label('Confirm Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: _validateConfirmPassword,
            decoration: _inputDeco(
              hint: 'Re-enter password',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() =>
                    _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── STEP 2: Player profile + CV ───────────────────────────────────────────
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Player Profile', icon: Icons.sports_tennis_rounded),
          const SizedBox(height: 20),

          // Skill level dropdown
          _label('Skill Level'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedLevel,
            validator: _validateLevel,
            decoration: _inputDeco(
                hint: 'Select your level',
                icon: Icons.bar_chart_rounded),
            items: _levels.map((l) {
              return DropdownMenuItem(
                value: l,
                child: Text(l,
                    style: const TextStyle(
                        fontSize: 14, color: _kNavy)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedLevel = v),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(14),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Play style — radio buttons
          _label('Play Style'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAF0)),
            ),
            child: Column(
              children: _playStyles.map((style) {
                return RadioListTile<String>(
                  value: style,
                  groupValue: _playStyle,
                  title: Text(style,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _kNavy)),
                  activeColor: _kNavy,
                  dense: true,
                  onChanged: (v) =>
                      setState(() => _playStyle = v ?? _playStyle),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Hours per week — slider
          _label(
              'Practice Hours / Week: ${_hoursPerWeek.round()} hrs'),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kNavy,
              inactiveTrackColor: const Color(0xFFE0E4EC),
              thumbColor: _kNavy,
              overlayColor: _kNavy.withOpacity(0.1),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: Slider(
              value: _hoursPerWeek,
              min: 1,
              max: 40,
              divisions: 39,
              onChanged: (v) => setState(() => _hoursPerWeek = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 hr',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
              Text('40 hrs',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),

          // Bio — multiline
          _label('Short Bio (optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: _inputDeco(
              hint:
                  'Tell other players a bit about yourself...',
              icon: Icons.edit_note_rounded,
            ).copyWith(
              prefixIcon: null,
              contentPadding: const EdgeInsets.all(14),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 4),

          // ── CV PDF Upload ─────────────────────────────────────────────
          _label('CV / Résumé (PDF only, max 5 MB)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickCV,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cvFilePath != null
                    ? _kGreen.withOpacity(0.05)
                    : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _cvError != null
                      ? _kRed
                      : _cvFilePath != null
                          ? _kGreen
                          : const Color(0xFFD0D5E0),
                  width: _cvFilePath != null ? 1.5 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _cvFilePath != null
                          ? _kGreen.withOpacity(0.12)
                          : _kNavy.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _cvFilePath != null
                          ? Icons.picture_as_pdf_rounded
                          : Icons.upload_file_rounded,
                      color: _cvFilePath != null ? _kGreen : _kNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cvFilePath != null
                              ? _cvFileName!
                              : 'Upload your CV',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _cvFilePath != null
                                ? _kGreen
                                : _kNavy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cvFilePath != null
                              ? 'PDF uploaded — tap to replace'
                              : 'PDF format only · max 5 MB',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _cvFilePath != null
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: _cvFilePath != null
                        ? _kGreen
                        : Colors.grey.shade400,
                    size: _cvFilePath != null ? 22 : 16,
                  ),
                ],
              ),
            ),
          ),
          if (_cvError != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.error_outline, color: _kRed, size: 14),
              const SizedBox(width: 4),
              Text(_cvError!,
                  style: const TextStyle(color: _kRed, fontSize: 12)),
            ]),
          ],
          const SizedBox(height: 20),

          // Notifications toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAF0)),
            ),
            child: SwitchListTile(
              value: _receiveNotifications,
              onChanged: (v) =>
                  setState(() => _receiveNotifications = v),
              activeColor: _kNavy,
              title: const Text(
                'Match Notifications',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kNavy),
              ),
              subtitle: Text(
                'Receive alerts for upcoming matches',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12),
              ),
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: _kNavy, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (v) =>
                      setState(() => _acceptTerms = v ?? false),
                  activeColor: _kNavy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () =>
                              debugPrint('Terms tapped'),
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              color: _kNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () =>
                              debugPrint('Privacy tapped'),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: _kNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Navigation buttons ─────────────────────────────────────────────────────
  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        children: [
          if (_currentStep == 0)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goToStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),

          if (_currentStep == 1) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Create Account',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kNavy),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back',
                    style: TextStyle(
                        color: _kNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _goToStep2() {
    // Only validate step-1 fields
    final step1Valid = _formKey.currentState!.validate();
    if (step1Valid) setState(() => _currentStep = 1);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: _kNavy,
        ),
      );

  Widget _sectionTitle(String text, {required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _kNavy, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _kNavy,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon:
          Icon(icon, color: Colors.grey.shade400, size: 20),
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
// STEP INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(0, 'Account', current),
        Expanded(
          child: Container(
            height: 2,
            color: current >= 1
                ? Colors.white
                : Colors.white.withOpacity(0.3),
          ),
        ),
        _dot(1, 'Profile', current),
      ],
    );
  }

  Widget _dot(int step, String label, int current) {
    final bool done   = current > step;
    final bool active = current == step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? Colors.white : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: done || active
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded,
                    color: _kNavy, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: active ? _kNavy : Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active || done
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORD STRENGTH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8)                        score++;
    if (RegExp(r'[A-Z]').hasMatch(password))         score++;
    if (RegExp(r'[0-9]').hasMatch(password))         score++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(password))  score++;
    return score;
  }

  Color get _color {
    switch (_strength) {
      case 1: return _kRed;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return _kGreen;
      default: return Colors.transparent;
    }
  }

  String get _label {
    switch (_strength) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < _strength
                      ? _color
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $_label',
          style: TextStyle(
              color: _color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
