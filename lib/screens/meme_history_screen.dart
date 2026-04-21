import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../data/meme_manifest.dart';
import '../models/meme.dart';
import '../models/meme_data.dart';
import '../services/drop_service.dart';
import 'meme_card_screen.dart';

class MemeHistoryScreen extends ConsumerStatefulWidget {
  const MemeHistoryScreen({super.key});

  @override
  ConsumerState<MemeHistoryScreen> createState() => _MemeHistoryScreenState();
}

class _MemeHistoryScreenState extends ConsumerState<MemeHistoryScreen> {
  List<DropHistory> _history = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ds = ref.read(dropServiceProvider);
    final history = await ds.getDropHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _loaded = true;
      });
    }
  }

  String _formatDateTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$mm.$dd.$yy · $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'THE LOG',
          style: TextStyle(letterSpacing: 6, fontSize: 14),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'EVERY DROP. EVEN THE ONES YOU LET GO.',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Color(0xFF444444),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(
                          child: Text(
                            'Nothing has been dropped yet.\nThe void stares back.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                              height: 1.8,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final entry = _history[index];
                            final rarity = Rarity.values.firstWhere(
                              (r) => r.name == entry.rarity,
                              orElse: () => Rarity.normie,
                            );
                            final rarityColor = AppColors.forRarity(rarity);

                            // Look up meme data
                            MemeData? memeData;
                            if (entry.memeId.isNotEmpty) {
                              try {
                                memeData = kMemeManifest.firstWhere(
                                    (m) => m.id == entry.memeId);
                              } catch (_) {
                                memeData = null;
                              }
                            }

                            final memeName = memeData?.name ??
                                entry.rarity.toUpperCase();

                            return GestureDetector(
                              onTap: memeData != null
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MemeCardScreen(
                                            meme: memeData!,
                                            acquiredAt: entry.openedAt,
                                            viewOnly: true,
                                            isFirstView: false,
                                          ),
                                        ),
                                      )
                                  : null,
                              child: SizedBox(
                                height: 56,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: rarityColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            memeName.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              letterSpacing: 1,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDateTime(entry.openedAt),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF444444),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      entry.stashed ? 'STASHED' : 'LOST',
                                      style: TextStyle(
                                        fontSize: 8,
                                        letterSpacing: 2,
                                        color: entry.stashed
                                            ? rarityColor
                                            : const Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
