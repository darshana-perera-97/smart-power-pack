import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BulbSwitchScreen extends StatefulWidget {
  const BulbSwitchScreen({super.key});

  @override
  State<BulbSwitchScreen> createState() => _BulbSwitchScreenState();
}

class _BulbSwitchScreenState extends State<BulbSwitchScreen> {
  // Firebase database references
  final DatabaseReference _switchDatabase = FirebaseDatabase.instance.ref('/switch-1');
  final DatabaseReference _timerDatabase = FirebaseDatabase.instance.ref('/timer');
  final DatabaseReference _timerValDatabase = FirebaseDatabase.instance.ref('/timer-val');
  
  // Bulb switch state
  bool _isBulbOn = false;
  bool _isLoading = false;
  bool _isConnected = false;
  String _statusMessage = 'Connecting to Firebase...';
  Timer? _pollingTimer;
  bool _isUserToggling = false;
  
  // Timer switch state
  bool _isTimerOn = false;
  bool _isTimerLoading = false;
  bool _isTimerUserToggling = false;
  
  // Timer value state
  double _timerValue = 500.0;
  bool _isSliderUserToggling = false;

  @override
  void initState() {
    super.initState();
    _loadInitialStates();
    _setupRealtimeListeners();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialStates() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading state from Firebase...';
    });

    try {
      // Load bulb switch state
      final switchSnapshot = await _switchDatabase.once();
      final switchState = switchSnapshot.snapshot.value as bool?;

      if (switchState == null) {
        await _switchDatabase.set(false);
        setState(() {
          _isBulbOn = false;
        });
      } else {
        setState(() {
          _isBulbOn = switchState;
        });
      }

      // Load timer switch state
      final timerSnapshot = await _timerDatabase.once();
      final timerState = timerSnapshot.snapshot.value as bool?;

      if (timerState == null) {
        await _timerDatabase.set(false);
        setState(() {
          _isTimerOn = false;
        });
      } else {
        setState(() {
          _isTimerOn = timerState;
        });
      }

      // Load timer value
      final timerValSnapshot = await _timerValDatabase.once();
      final timerVal = timerValSnapshot.snapshot.value;
      
      if (timerVal != null) {
        setState(() {
          _timerValue = (timerVal as num).toDouble();
        });
      } else {
        await _timerValDatabase.set(500);
        setState(() {
          _timerValue = 500.0;
        });
      }

      setState(() {
        _isLoading = false;
        _isConnected = true;
        _statusMessage = 'Connected to Firebase';
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Error connecting to Firebase';
      });
    }
  }

  void _setupRealtimeListeners() {
    // Listen for bulb switch changes
    _switchDatabase.onValue.listen((event) {
      final switchState = event.snapshot.value as bool?;
      if (switchState != null && !_isUserToggling) {
        setState(() {
          _isBulbOn = switchState;
          _isConnected = true;
          _statusMessage = 'Connected to Firebase';
        });
      }
    });

    // Listen for timer switch changes
    _timerDatabase.onValue.listen((event) {
      final timerState = event.snapshot.value as bool?;
      if (timerState != null && !_isTimerUserToggling) {
        setState(() {
          _isTimerOn = timerState;
        });
      }
    });

    // Listen for timer value changes
    _timerValDatabase.onValue.listen((event) {
      final timerVal = event.snapshot.value;
      if (timerVal != null && !_isSliderUserToggling) {
        setState(() {
          _timerValue = (timerVal as num).toDouble();
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
    if (_isUserToggling || _isTimerUserToggling || _isSliderUserToggling) return;
    
    try {
      final switchSnapshot = await _switchDatabase.once();
      final switchState = switchSnapshot.snapshot.value as bool?;
      
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
      await _switchDatabase.set(_isBulbOn);
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

  Future<void> _toggleTimer() async {
    setState(() {
      _isTimerOn = !_isTimerOn;
      _isTimerLoading = true;
      _isTimerUserToggling = true;
    });

    try {
      await _timerDatabase.set(_isTimerOn);
      setState(() {
        _isTimerLoading = false;
      });
      
      // Reset the flag after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isTimerUserToggling = false;
          });
        }
      });
    } catch (error) {
      // Revert the UI change if Firebase update fails
      setState(() {
        _isTimerOn = !_isTimerOn;
        _isTimerLoading = false;
        _isTimerUserToggling = false;
      });
    }
  }

  Future<void> _updateTimerValue(double value) async {
    setState(() {
      _timerValue = value;
      _isSliderUserToggling = true;
    });

    try {
      await _timerValDatabase.set(value.toInt());
      
      // Reset the flag after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isSliderUserToggling = false;
          });
        }
      });
    } catch (error) {
      // Revert the UI change if Firebase update fails
      setState(() {
        _isSliderUserToggling = false;
      });
    }
  }

  Widget _buildSwitch(String label, bool isOn, VoidCallback onToggle, bool isLoading) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: isLoading ? null : onToggle,
          child: Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isOn ? Colors.green : Colors.grey.shade400,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: isOn ? 40 : 4,
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
          'Toggle to turn ${label.toLowerCase()} ${isOn ? 'OFF' : 'ON'}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
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
                  'Smart Bulb Switches',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Switch 1 Section
                const Text(
                  'Switch 1',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Bulb Display with Timer Indicator
                Stack(
                  children: [
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
                    // Timer Indicator
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.access_time,
                        size: 20,
                        color: _isTimerOn ? Colors.yellow.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Bulb Switch
                _buildSwitch('Bulb', _isBulbOn, _toggleBulb, _isLoading),

                const SizedBox(height: 30),

                // Timer Switch
                _buildSwitch('Timer', _isTimerOn, _toggleTimer, _isTimerLoading),

                const SizedBox(height: 20),

                // Timer Value Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Timer Value:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _timerValue.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Timer Value Slider
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Slider Value Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _timerValue.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Slider
                      Slider(
                        value: _timerValue,
                        min: 1,
                        max: 3600,
                        divisions: 3599,
                        onChanged: (value) {
                          setState(() {
                            _timerValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _updateTimerValue(value);
                        },
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey.shade300,
                      ),
                      // Slider Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '3600',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
