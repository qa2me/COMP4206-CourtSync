// lib/pages/friends_page.dart

import 'package:flutter/material.dart';
import 'friends_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy  = Color(0xFF1A2A4A);
const Color _kGreen = Color(0xFF4CAF50);
const Color _kBlue  = Color(0xFF2196F3);
const Color _kRed   = Color(0xFFE53935);
const Color _kGold  = Color(0xFFFFD700);
const Color _kBg    = Color(0xFFF4F6F9);

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _store = FriendsStore.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _store.init();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose(); // do NOT call _store.dispose() — it's a singleton
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final pendingCount = _store.pendingRequests.length;
        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Friends',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, size: 22),
                tooltip: 'Add Friend',
                onPressed: _showAddFriendSheet,
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
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
                      const Icon(Icons.group_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('FRIENDS (${_store.friends.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('REQUESTS'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        _Badge(pendingCount),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _FriendsTab(store: _store),
              _RequestsTab(store: _store),
            ],
          ),
        );
      },
    );
  }

  void _showAddFriendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFriendSheet(store: _store),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRIENDS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _FriendsTab extends StatefulWidget {
  final FriendsStore store;
  const _FriendsTab({required this.store});

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppUser> _filtered(List<AppUser> friends) {
    if (_query.isEmpty) return friends;
    final q = _query.toLowerCase();
    return friends
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final friends  = widget.store.friends;
        final filtered = _filtered(friends);

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.grey, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Count label
            if (friends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                child: Row(
                  children: [
                    Text(
                      _query.isEmpty
                          ? '${friends.length} friend${friends.length == 1 ? '' : 's'}'
                          : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: friends.isEmpty
                  ? const _EmptyState(
                      icon: Icons.group_rounded,
                      message: 'No friends yet',
                      sub: 'Tap the + button to find and add players',
                    )
                  : filtered.isEmpty
                      ? _EmptyState(
                          icon: Icons.search_off_rounded,
                          message: 'No results for "$_query"',
                          sub: 'Try a different name or email',
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FriendCard(
                              user: filtered[i],
                              onViewProfile: () =>
                                  _showProfile(context, filtered[i]),
                              onUnfriend: () async {
                                try {
                                  await widget.store
                                      .unfriend(filtered[i].id);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(
                                                'Failed to unfriend: $e')));
                                  }
                                }
                              },
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  void _showProfile(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(user: user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUESTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  final FriendsStore store;
  const _RequestsTab({required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final requests = store.pendingRequests;
        if (requests.isEmpty) {
          return const _EmptyState(
            icon: Icons.notifications_none_rounded,
            message: 'No pending requests',
            sub: 'Friend requests from other players will appear here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: requests.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RequestCard(
              user: requests[i],
              onAccept: () async {
                try {
                  await store.acceptRequest(requests[i].id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to accept: $e')));
                  }
                }
              },
              onDecline: () async {
                try {
                  await store.declineRequest(requests[i].id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to decline: $e')));
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRIEND CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onViewProfile;
  final VoidCallback onUnfriend;
  const _FriendCard({
    required this.user,
    required this.onViewProfile,
    required this.onUnfriend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(
          children: [
            _Avatar(name: user.name, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kNavy)),
                  const SizedBox(height: 3),
                  Row(children: [
                    _MiniStat(
                        label: 'UTR', value: user.utr, color: _kGreen),
                    const SizedBox(width: 10),
                    _MiniStat(
                        label: 'Rank',
                        value: '#${user.rank}',
                        color: _kBlue),
                    const SizedBox(width: 10),
                    _MiniStat(
                        label: 'W-Rate',
                        value:
                            '${(user.winRate * 100).toStringAsFixed(0)}%',
                        color: _kNavy),
                  ]),
                ],
              ),
            ),
            Column(
              children: [
                _ActionButton(
                  icon: Icons.person_search_rounded,
                  color: _kNavy,
                  tooltip: 'View Profile',
                  onTap: onViewProfile,
                ),
                const SizedBox(height: 6),
                _ActionButton(
                  icon: Icons.person_remove_rounded,
                  color: _kRed,
                  tooltip: 'Unfriend',
                  onTap: () => _confirmUnfriend(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnfriend(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${user.name}?',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: _kNavy, fontSize: 16)),
        content: const Text('They will be removed from your friends list.',
            style: TextStyle(fontSize: 14, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color: _kNavy, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onUnfriend();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUEST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _RequestCard({
    required this.user,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _kBlue, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          _Avatar(name: user.name, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _kNavy)),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: [
                  _MiniStat(
                      label: 'UTR', value: user.utr, color: _kGreen),
                  const SizedBox(width: 10),
                  _MiniStat(
                      label: 'Rank',
                      value: '#${user.rank}',
                      color: _kBlue),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _ActionButton(
                icon: Icons.check_rounded,
                color: _kGreen,
                tooltip: 'Accept',
                onTap: onAccept,
              ),
              const SizedBox(height: 6),
              _ActionButton(
                icon: Icons.close_rounded,
                color: _kRed,
                tooltip: 'Decline',
                onTap: onDecline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD FRIEND BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _AddFriendSheet extends StatefulWidget {
  final FriendsStore store;
  const _AddFriendSheet({required this.store});

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListenableBuilder(
            listenable: widget.store,
            builder: (context, __) {
              final results = widget.store.discover(_query);

              return CustomScrollView(
                controller: scrollCtrl,
                slivers: [
                  // ── Static header ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.person_add_rounded,
                                  color: _kNavy, size: 20),
                              SizedBox(width: 8),
                              Text('Add Friends',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _kNavy)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _ctrl,
                              onChanged: (v) =>
                                  setState(() => _query = v),
                              decoration: const InputDecoration(
                                hintText: 'Search by name or email...',
                                hintStyle: TextStyle(
                                    color: Colors.grey, fontSize: 13),
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // ── Results ──────────────────────────────────────────
                  if (results.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        icon: Icons.search_off_rounded,
                        message: _query.isEmpty
                            ? 'All players are already your friends!'
                            : 'No players found for "$_query"',
                        sub: '',
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final user   = results[i];
                            final status =
                                widget.store.statusOf(user.id);
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10),
                              child: _DiscoverCard(
                                user: user,
                                status: status,
                                onSend: () async {
                                  try {
                                    await widget.store
                                        .sendRequest(user.id);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Failed to send request: $e')));
                                    }
                                  }
                                },
                                onSimulateAccept: () {
                                  widget.store
                                      .simulateIncoming(user.id);
                                },
                              ),
                            );
                          },
                          childCount: results.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISCOVER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DiscoverCard extends StatelessWidget {
  final AppUser user;
  final FriendStatus status;
  final VoidCallback onSend;
  final VoidCallback onSimulateAccept;
  const _DiscoverCard({
    required this.user,
    required this.status,
    required this.onSend,
    required this.onSimulateAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _Avatar(name: user.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kNavy)),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 5),
                Row(children: [
                  _MiniStat(
                      label: 'UTR', value: user.utr, color: _kGreen),
                  const SizedBox(width: 8),
                  _MiniStat(
                      label: 'Rank',
                      value: '#${user.rank}',
                      color: _kBlue),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
              status: status,
              onSend: onSend,
              onSimulateAccept: onSimulateAccept),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final FriendStatus status;
  final VoidCallback onSend;
  final VoidCallback onSimulateAccept;
  const _SendButton({
    required this.status,
    required this.onSend,
    required this.onSimulateAccept,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case FriendStatus.none:
        return ElevatedButton.icon(
          onPressed: onSend,
          icon: const Icon(Icons.person_add_rounded, size: 14),
          label: const Text('Add',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kNavy,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        );
      case FriendStatus.sent:
        return GestureDetector(
          onLongPress: onSimulateAccept,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text('Sent',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        );
      case FriendStatus.incoming:
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('Respond',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12)),
        );
      case FriendStatus.friend:
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGreen.withOpacity(0.4)),
          ),
          child: const Text('Friends',
              style: TextStyle(
                  color: _kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final AppUser user;
  const _ProfileSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), _kNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _Avatar(name: user.name, size: 64, borderColor: _kGreen),
                const SizedBox(height: 12),
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _kGold.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: _kGold, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Rank #${user.rank}  ·  ${user.utr} UTR',
                        style: const TextStyle(
                            color: _kGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _StatTile(
                    label: 'Played',
                    value: '${user.matchesPlayed}',
                    icon: Icons.sports_tennis_rounded,
                    color: _kNavy),
                _vDivider(),
                _StatTile(
                    label: 'Won',
                    value: '${user.matchesWon}',
                    icon: Icons.emoji_events_rounded,
                    color: _kGreen),
                _vDivider(),
                _StatTile(
                    label: 'Win Rate',
                    value:
                        '${(user.winRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.bar_chart_rounded,
                    color: _kBlue),
                _vDivider(),
                _StatTile(
                    label: 'Streak',
                    value: '${user.winStreak}🔥',
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.orange),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kNavy),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Close',
                    style: TextStyle(
                        color: _kNavy, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1,
      height: 48,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? borderColor;
  const _Avatar(
      {required this.name, required this.size, this.borderColor});

  Color _colorFromName(String n) {
    const colors = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
      Color(0xFF00695C),
      Color(0xFF283593),
    ];

    if (n.trim().isEmpty) {
      return colors[0];
    }

    return colors[n.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = _colorFromName(name);
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2.5)
            : null,
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.35)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$label ',
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
          TextSpan(
              text: value,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }
}