import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_service.dart';

const Color _kNavy = Color(0xFF1A2A4A);
const Color _kBlue = Color(0xFF2196F3);

class NearbyCourtsPage extends StatefulWidget {
  const NearbyCourtsPage({super.key});

  @override
  State<NearbyCourtsPage> createState() => _NearbyCourtsPageState();
}

class _NearbyCourtsPageState extends State<NearbyCourtsPage> {
  final MapController _mapController = MapController();
  int? _selectedIndex;
  List<Map<String, dynamic>> _courts = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = DatabaseService.instance.courtsStream.listen((list) {
      if (mounted) setState(() => _courts = list);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _goToCourt(int index) {
    final court = _courts[index];
    setState(() => _selectedIndex = index);
    _mapController.move(
      LatLng(
        (court['lat'] as num).toDouble(),
        (court['lng'] as num).toDouble(),
      ),
      14,
    );
  }

  void _showCourtInfo(int index) {
    _goToCourt(index);
    final court = _courts[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.sports_tennis, color: _kNavy, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(court['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kNavy)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(court['desc'] ?? '',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kNavy.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded,
                      color: _kBlue, size: 20),
                  const SizedBox(width: 10),
                  Text(court['phone'] ?? '',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kNavy)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(court['area'] ?? '',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: _kNavy)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.58;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          SizedBox(
            height: mapHeight,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(23.58, 58.38),
                initialZoom: 9.5,
                onTap: (_, __) => setState(() => _selectedIndex = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'flutter_template',
                ),
                MarkerLayer(
                  markers: _courts.asMap().entries.map((e) {
                    final i = e.key;
                    final c = e.value;
                    return Marker(
                      point: LatLng(
                        (c['lat'] as num).toDouble(),
                        (c['lng'] as num).toDouble(),
                      ),
                      width: 90,
                      height: 90,
                      child: GestureDetector(
                        onTap: () => _goToCourt(i),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_tennis,
                              color: _selectedIndex == i ? _kBlue : Colors.red,
                              size: 30,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedIndex == i
                                    ? _kNavy
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedIndex == i
                                      ? _kBlue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                c['area'] ?? '',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedIndex == i
                                      ? Colors.white
                                      : _kNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Courts list
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: _kNavy, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Nearby Courts',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _kNavy,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_courts.length} locations',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _courts.length,
                      itemBuilder: (_, i) {
                        final court = _courts[i];
                        final isSelected = _selectedIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => _showCourtInfo(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _kNavy
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? _kBlue
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.15)
                                          : _kNavy.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.sports_tennis,
                                      color: isSelected
                                          ? Colors.white
                                          : _kNavy,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          court['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.white
                                                : _kNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          court['desc'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white70
                                                : Colors.grey.shade500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: isSelected
                                        ? Colors.white54
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}
