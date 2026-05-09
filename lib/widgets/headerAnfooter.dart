import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_template/pages/friends_page.dart';
import 'package:flutter_template/pages/user_matches.dart';
import '../pages/MyHomePage.dart';
import '../pages/matches.dart';
import '../pages/nearby_courts_page.dart';
import '../pages/statistics_page.dart';
import '../pages/signin.dart';
import '../services/database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy   = Color(0xFF1A2A4A);
const Color _kAccent = Color(0xFF2ECC71);

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────────────────────────────────────
class HeaderAndFooter extends StatefulWidget {
  const HeaderAndFooter({super.key});

  @override
  State<HeaderAndFooter> createState() => _HeaderAndFooterState();
}

class _HeaderAndFooterState extends State<HeaderAndFooter> {
  int _selectedIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _profileSub;
  Map<String, dynamic>? _userProfile;

  // ── Your real pages ────────────────────────────────────────────────────────
  final List<Widget> _pages = const [
    NearbyCourtsPage(), // index 0 — location tab
    HomePageBody(),                            // index 1 — home
    MatchesPageBody(),                         // index 2 — matches
  ];

  @override
  void initState() {
    super.initState();
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      _profileSub = DatabaseService.instance.userProfileStream(uid).listen((p) {
        if (mounted) setState(() => _userProfile = p);
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  // ── Header (kept exactly like your original) ───────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _kNavy,
      height: 150,
      padding: const EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo — unchanged from original
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/mainLogo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),

          // Profile button — taps to open endDrawer
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: SizedBox(
              width: 90,
              height: 90,
              child: Image.asset(
                'assets/images/blackProfileLogo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav (unchanged from original) ──────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.location_on, 0),
            _buildNavItem(Icons.home, 1),
            _buildNavItem(Icons.sports_tennis, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconData, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? _kNavy : Colors.transparent,
        ),
        child: Icon(
          iconData,
          color: isSelected ? Colors.white : Colors.grey,
          size: 26,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      endDrawer: _ProfileDrawer(profile: _userProfile),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// END DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileDrawer extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _ProfileDrawer({this.profile});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Profile header
          _DrawerHeader(profile: profile),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerMenuItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistics',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatisticsPage(),
                        ),
                      );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.group_rounded,
                  label: 'Friends',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FriendsPage(),
                        ));
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.sports_tennis_rounded,
                  label: 'My Matches',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserMatchesPage(),
                        ));
                  },
                ),

                // Divider — visually separates Settings
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                ),

                _DrawerMenuItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInPage(),
                        ));
                  },
                ),
              ],
            ),
          ),

          // Sign out
          _SignOutButton(),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _DrawerHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final name = profile?['firstName'] != null
        ? '${profile!['firstName']} ${profile!['lastName'] ?? ''}'
        : db.currentUserName;
    final email = db.currentUserEmail;
    final rank = profile?['rank'] ?? 42;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 28,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent, width: 2.5),
              color: Colors.white.withOpacity(0.1),
            ),
            child: const ClipOval(
              child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
            ),
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kAccent.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: _kAccent, size: 14),
                const SizedBox(width: 5),
                Text(
                  'Rank #$rank',
                  style: const TextStyle(
                    color: _kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER MENU ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kNavy.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kNavy, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
            letterSpacing: 0.1,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFBBBBBB),
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        horizontalTitleGap: 12,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN OUT BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFFE0E0)),
          ),
          backgroundColor: const Color(0xFFFFF5F5),
        ),
        onPressed: () async {
          await DatabaseService.instance.signOut();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (_) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER (location tab only)
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          color: _kNavy,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}