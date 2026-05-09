import 'package:flutter/material.dart';
import 'package:firebase_dart/firebase_dart.dart';
import 'signup.dart';
import '../services/database_service.dart';
import '../widgets/headerAnfooter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy   = Color(0xFF1A2A4A);
const Color _kGreen  = Color(0xFF4CAF50);
const Color _kBg     = Color(0xFFF4F6F9);
const Color _kRed    = Color(0xFFE53935);

// ─────────────────────────────────────────────────────────────────────────────
// SIGN-IN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe      = false;
  bool _isLoading       = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ── Friendly error message ──────────────────────────────────────────────────
  String _friendlyAuthError(dynamic e) {
    // Extract the error code whether it's a FirebaseAuthException or raw string
    String code = '';
    if (e is FirebaseAuthException) {
      code = e.code.toLowerCase();
    } else {
      // firebase_dart sometimes throws plain exceptions whose toString()
      // contains the code inside brackets, e.g. "[firebase_auth/wrong-password]"
      final raw = e.toString().toLowerCase();
      final match = RegExp(r'\[firebase_auth/([^\]]+)\]').firstMatch(raw);
      if (match != null) {
        code = match.group(1) ?? '';
      } else {
        code = raw;
      }
    }

    switch (code) {
      case 'wrong-password':
      case 'invalid-password':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'invalid-credential':
      // Firebase v10+ collapses wrong-email AND wrong-password into this code
        return 'Incorrect email or password. Please try again.';
      default:
        return 'Incorrect email or password. Please try again.';
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await DatabaseService.instance.signIn(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signed in successfully!'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HeaderAndFooter()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(e)),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailCtrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy)),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kNavy)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, emailCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _kNavy),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    emailCtrl.dispose();
    if (email == null || email.isEmpty) return;
    try {
      await DatabaseService.instance.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent!'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(e)),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),

                      // ── Logo ──────────────────────────────────────────────
                      Image.asset(
                        'assets/images/mainLogo.png',
                        width: 110,
                        height: 110,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _kGreen, width: 2),
                          ),
                          child: const Icon(Icons.sports_tennis,
                              color: _kGreen, size: 44),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // App name
                      const Text(
                        'CourtSync',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your tennis companion',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Card ─────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _kNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to continue playing',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 24),

                              // Email
                              _buildLabel('Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType:
                                    TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                                decoration: _inputDecoration(
                                  hint: 'you@example.com',
                                  icon: Icons.email_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _buildLabel('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _handleSignIn(),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
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
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Remember me + Forgot password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(
                                              () => _rememberMe =
                                                  v ?? false),
                                          activeColor: _kNavy,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          side: BorderSide(
                                              color: Colors.grey.shade400),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Remember me',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _handleForgotPassword(),
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: _kNavy,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Sign in button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kNavy,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Divider
                              Row(children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade200)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text('or continue with',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12)),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade200)),
                              ]),

                              const SizedBox(height: 20),

                              // Social buttons row
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      label: 'Google',
                                      icon: Icons.g_mobiledata_rounded,
                                      iconColor: const Color(0xFFEA4335),
                                      onTap: () =>
                                          debugPrint('Google sign-in'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SocialButton(
                                      label: 'Apple',
                                      icon: Icons.apple_rounded,
                                      iconColor: Colors.black,
                                      onTap: () =>
                                          debugPrint('Apple sign-in'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpPage()),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: _kNavy,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: _kNavy,
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
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
// SOCIAL BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}