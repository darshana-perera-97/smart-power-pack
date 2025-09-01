import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BulbSwitchScreen extends StatefulWidget {
  const BulbSwitchScreen({super.key});

  @override
  State<BulbSwitchScreen> createState() => _BulbSwitchScreenState();
}

class _BulbSwitchScreenState extends State<BulbSwitchScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('/switch-1');
  bool _isBulbOn = false;
  bool _isLoading = false;
  bool _isConnected = false;
  String _statusMessage = 'Connecting to Firebase...';
  Timer? _pollingTimer;
  bool _isUserToggling = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _setupRealtimeListener();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading state from Firebase...';
    });

    try {
      final snapshot = await _database.once();
      final switchState = snapshot.snapshot.value as bool?;

      if (switchState == null) {
        // If no data exists, create initial state (OFF)
        await _database.set(false);
        setState(() {
          _isBulbOn = false;
          _isLoading = false;
          _isConnected = true;
          _statusMessage = 'Connected to Firebase';
        });
      } else {
        setState(() {
          _isBulbOn = switchState;
          _isLoading = false;
          _isConnected = true;
          _statusMessage = 'Connected to Firebase';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Error connecting to Firebase';
      });
    }
  }

  void _setupRealtimeListener() {
    _database.onValue.listen((event) {
      final switchState = event.snapshot.value as bool?;
      if (switchState != null) {
        setState(() {
          _isBulbOn = switchState;
          _isConnected = true;
          _statusMessage = 'Connected to Firebase';
        });
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkFirebaseState();
    });
  }

  Future<void> _checkFirebaseState() async {
    // Skip polling if user is currently toggling to avoid conflicts
    if (_isUserToggling) return;
    
    try {
      final snapshot = await _database.once();
      final switchState = snapshot.snapshot.value as bool?;
      
      if (switchState != null) {
        setState(() {
          _isBulbOn = switchState;
          _isConnected = true;
          _statusMessage = 'Connected to Firebase (Polling)';
        });
      }
    } catch (error) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Error polling Firebase';
      });
    }
  }

  Future<void> _toggleBulb() async {
    // Update UI immediately for better user experience
    setState(() {
      _isBulbOn = !_isBulbOn;
      _isLoading = true;
      _isUserToggling = true;
      _statusMessage = 'Updating Firebase...';
    });

    try {
      await _database.set(_isBulbOn);
      setState(() {
        _isLoading = false;
        _isConnected = true;
        _statusMessage = 'Connected to Firebase (Polling)';
      });
      
      // Reset the flag after a short delay to allow polling to resume
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isUserToggling = false;
          });
        }
      });
    } catch (error) {
      // Revert the UI change if Firebase update fails
      setState(() {
        _isBulbOn = !_isBulbOn;
        _isLoading = false;
        _isConnected = false;
        _isUserToggling = false;
        _statusMessage = 'Error updating Firebase';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Smart Bulb Switch',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Bulb Display
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isBulbOn ? Colors.yellow.shade300 : Colors.grey.shade300,
                  boxShadow: _isBulbOn
                      ? [
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.lightbulb,
                  size: 60,
                  color: _isBulbOn ? Colors.yellow.shade700 : Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              // Switch
              GestureDetector(
                onTap: _isLoading ? null : _toggleBulb,
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _isBulbOn ? Colors.green : Colors.grey.shade400,
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        left: _isBulbOn ? 40 : 4,
                        top: 4,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Toggle to turn bulb ${_isBulbOn ? 'OFF' : 'ON'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? Colors.green.shade50
                      : _isLoading
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _isConnected
                        ? Colors.green
                        : _isLoading
                            ? Colors.orange
                            : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLoading
                          ? Icons.hourglass_empty
                          : _isConnected
                              ? Icons.wifi
                              : Icons.wifi_off,
                      color: _isConnected
                          ? Colors.green
                          : _isLoading
                              ? Colors.orange
                              : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isConnected
                              ? Colors.green.shade700
                              : _isLoading
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Polling indicator
              if (_isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync,
                        color: Colors.blue,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Polling every 1 second',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Current State
              Text(
                'Current State: ${_isBulbOn ? 'ON' : 'OFF'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isBulbOn ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
