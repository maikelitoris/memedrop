import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../services/collection_service.dart';
import '../services/drop_service.dart';
import '../services/streak_service.dart';
import 'meme_history_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hapticsEnabled = true;
  bool _crtEnabled = false;
  int _streak = 0;
  int _longestStreak = 0;
  int _totalStashed = 0;
  int _totalOpened = 0;
  int _historyStashed = 0;
  String _anonId = '';
  String _selectedContainer = 'brain';
  bool _loaded = false;

  // Available container models (must match home_screen.dart)
  static const List<String> _containerModels = [
    'brain',
    'pepe_compressed',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cs = await ref.read(collectionServiceProvider.future);
    final ss = ref.read(streakServiceProvider);
    final ds = ref.read(dropServiceProvider);
    final streak = await ss.getCurrentStreak();
    final longest = await ss.getLongestStreak();
    final stats = await ds.getStashStats();

    if (mounted) {
      setState(() {
        _hapticsEnabled = cs.isHapticsEnabled();
        _crtEnabled = cs.isCrtEnabled();
        _selectedContainer = cs.getSelectedContainer();
        _streak = streak;
        _longestStreak = longest;
        _totalStashed = cs.getCollection().length;
        _totalOpened = stats['total'] ?? 0;
        _historyStashed = stats['stashed'] ?? 0;
        _anonId = cs.getAnonymousId();
        _loaded = true;
      });
    }
  }

  Future<void> _confirmPurge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'PURGE',
          style:
              TextStyle(letterSpacing: 4, fontSize: 13, color: Colors.white),
        ),
        content: const Text(
          'This cannot be undone. All memes will be lost.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL',
                style: TextStyle(color: Colors.white54, letterSpacing: 2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PURGE',
                style:
                    TextStyle(color: AppColors.destructive, letterSpacing: 2)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final cs = await ref.read(collectionServiceProvider.future);
      await cs.clearCollection();
      ref.invalidate(collectionServiceProvider);
      if (mounted) {
        setState(() => _totalStashed = 0);
        Navigator.of(context).pop();
      }
    }
  }

  String get _stashRateDisplay {
    if (_totalOpened == 0) return '—';
    return '${(_historyStashed / _totalOpened * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(letterSpacing: 6, fontSize: 14),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                _Row(
                  label: 'HAPTICS',
                  right: CupertinoSwitch(
                    value: _hapticsEnabled,
                    activeTrackColor: Colors.white,
                    onChanged: (v) async {
                      setState(() => _hapticsEnabled = v);
                      final cs =
                          await ref.read(collectionServiceProvider.future);
                      await cs.setHapticsEnabled(v);
                    },
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'CRT EFFECT',
                  right: CupertinoSwitch(
                    value: _crtEnabled,
                    activeTrackColor: Colors.white,
                    onChanged: (v) async {
                      setState(() => _crtEnabled = v);
                      final cs =
                          await ref.read(collectionServiceProvider.future);
                      await cs.setCrtEnabled(v);
                    },
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'CONTAINER',
                  right: DropdownButton<String>(
                    value: _selectedContainer,
                    dropdownColor: const Color(0xFF141414),
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                    items: _containerModels.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(model.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _selectedContainer = value);
                      final cs =
                          await ref.read(collectionServiceProvider.future);
                      await cs.setSelectedContainer(value);
                      // Navigate back to home screen to apply the change
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const _Divider(),
                const _Row(
                  label: 'DROP WINDOWS',
                  right: Text(
                    '00:00 UTC / 12:00 UTC',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Color(0xFF666666)),
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'ANONYMOUS ID',
                  right: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _anonId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('COPIED',
                              style: TextStyle(
                                  letterSpacing: 3, fontSize: 10)),
                          backgroundColor: Color(0xFF1A1A1A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      '${_anonId.substring(0, 8)}...',
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: Color(0xFF444444)),
                    ),
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'YOUR STREAK',
                  right: Text(
                    _streak > 0 ? '🔥 $_streak DAYS' : '—',
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white54),
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'LONGEST STREAK',
                  right: Text(
                    '$_longestStreak DAYS',
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white54),
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'TOTAL STASHED',
                  right: Text(
                    '$_totalStashed',
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white54),
                  ),
                ),
                const _Divider(),
                _Row(
                  label: 'STASH RATE',
                  right: Text(
                    _stashRateDisplay,
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white54),
                  ),
                ),
                const _Divider(),
                _NavRow(
                  label: 'HISTORY',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MemeHistoryScreen()),
                  ),
                ),
                const _Divider(),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _confirmPurge,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.destructive, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      AppStrings.purgeTheHoard,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 3,
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Widget right;

  const _Row({required this.label, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
          right,
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF444444), size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFF1A1A1A), height: 1, thickness: 1);
  }
}
