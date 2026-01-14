import 'package:flutter/material.dart';
import '../controllers/driver_tracking_controller.dart';
import '../services/location_permission_manager.dart';

class TripControlButton extends StatefulWidget {
  const TripControlButton({super.key});

  @override
  State<TripControlButton> createState() => _TripControlButtonState();
}

class _TripControlButtonState extends State<TripControlButton> with WidgetsBindingObserver {
  bool _isTracking = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState(); //refresh when coming back
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  Future<void> _loadState() async {
    final running =
    await DriverTrackingController.instance.isTrackingActive();
    if (!mounted) return;
    setState(() {
      _isTracking = running;
      _loading = false;
    });
  }

  Future<void> _onPressed() async {
    if (_isTracking) {
      // END TRIP
      await DriverTrackingController.instance.stopTracking();
    } else {
      // START TRIP
      final ready = await LocationPermissionManager.instance.ensureLocationReady();
      if (!ready) return;
      await DriverTrackingController.instance.startTracking();
    }
    await _loadState(); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CircularProgressIndicator();
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isTracking ? Colors.red : Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      onPressed: _onPressed,
      child: Text(
        _isTracking ? 'END TRIP' : 'START TRIP',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
