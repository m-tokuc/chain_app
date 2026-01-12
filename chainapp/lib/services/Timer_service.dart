import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerProvider extends ChangeNotifier {
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  TimerProvider() {
    debugPrint("✅ [TIMER SERVICE]: Provider yüklendi.");
  }

  int get selectedMinutes => _selectedMinutes;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;

  void setMinutes(int minutes) {
    if (!_isRunning && minutes > 0) {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      notifyListeners();
    }
  }

  void toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
    } else {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          _onFinished();
        }
      });
    }
    notifyListeners();
  }

  void _onFinished() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _selectedMinutes * 60;
    notifyListeners();

    try {
      await _audioPlayer.play(AssetSource('alarm.mp3'));
    } catch (e) {
      debugPrint("❌ Ses Hatası: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
