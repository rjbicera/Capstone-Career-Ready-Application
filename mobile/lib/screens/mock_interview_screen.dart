import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../services/auth_api_service.dart';
import '../theme/theme_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

enum InterviewState {
  checkingStatus,
  notReady,
  readyToStart,
  connecting,
  inProgress,
  completed,
  error,
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  InterviewState _state = InterviewState.checkingStatus;
  String? _errorMessage;
  Map<String, dynamic>? _statusData;
  String? _sessionId;

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;

  // Audio
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;

  // Interview flow
  String _currentQuestion = "Connecting to interviewer...";
  int _questionCount = 0;
  static const int _maxQuestions = 8;

  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
    _checkStatus();
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    _cleanup();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cleanup() async {
    await _wsSubscription?.cancel();
    await _channel?.sink.close(status.goingAway);
    if (_isRecording) await _recorder.stop();
    await _player.dispose();
    await _recorder.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final idToken = await user.getIdToken(true);

      final status = await AuthApiService.getInterviewStatus(idToken: idToken!);
      if (!mounted) return;

      setState(() {
        _statusData = status;
        if (status['ready'] == true) {
          _state = InterviewState.readyToStart;
        } else {
          _state = InterviewState.notReady;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = InterviewState.error;
        _errorMessage = 'Failed to check interview status: $e';
      });
    }
  }

  Future<void> _startInterview() async {
    setState(() => _state = InterviewState.connecting);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final idToken = await user.getIdToken(true);

      final result = await AuthApiService.startInterview(idToken: idToken!);
      if (!mounted) return;

      _sessionId = result['sessionId'] as String;

      // Connect to WebSocket
      await _connectWebSocket(idToken);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = InterviewState.error;
        _errorMessage = 'Failed to start interview: $e';
      });
    }
  }

  Future<void> _connectWebSocket(String idToken) async {
    if (_sessionId == null) return;

    final wsUrl = AuthApiService.getInterviewWebSocketUrl(_sessionId!, idToken);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsSubscription = _channel!.stream.listen(
        _onWebSocketMessage,
        onError: _onWebSocketError,
        onDone: _onWebSocketDone,
      );

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() {
        _state = InterviewState.inProgress;
        _currentQuestion = "Interviewer is joining...";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = InterviewState.error;
        _errorMessage = 'WebSocket connection failed: $e';
      });
    }
  }

  void _onWebSocketMessage(dynamic message) {
    if (!mounted) return;

    debugPrint('[WS] Received message type: ${message.runtimeType}, isBinary: ${message is List<int>}');

    // Handle both text and binary messages from Gemini Live
    if (message is String) {
      _handleTextMessage(message);
    } else if (message is List<int>) {
      // Binary audio data - play it
      _playAudio(message);
    }
  }

  void _handleTextMessage(String text) {
    debugPrint('[WS] Text message: $text');
    try {
      final json = _parseMessage(text);
      if (json != null) {
        _handleGeminiMessage(json);
      } else {
        // Plain text message (not JSON) - treat as interviewer speech
        _handleInterviewerText(text);
      }
    } catch (e) {
      debugPrint('[WS] Error parsing text message: $e');
    }
  }

  void _handleInterviewerText(String text) {
    if (text.trim().isEmpty) return;
    debugPrint('[WS] Interviewer text: $text');
    setState(() {
      if (text.contains('INTERVIEW_COMPLETE')) {
        _state = InterviewState.completed;
        _currentQuestion = 'Interview complete! Generating evaluation...';
        _completeInterview();
      } else {
        _currentQuestion = text;
        _questionCount++;
      }
    });
  }

  Map<String, dynamic>? _parseMessage(String data) {
    try {
      return jsonDecode(data);
    } catch (_) {
      return null;
    }
  }

  void _handleGeminiMessage(Map<String, dynamic> msg) {
    debugPrint('[WS] Parsed JSON message: $msg');
    // Gemini Live sends various message types
    // Check for text content in various formats
    String? text;
    if (msg['text'] != null) {
      text = msg['text'] as String;
    } else if (msg['content'] != null && msg['content'] is List && msg['content'].isNotEmpty) {
      final firstContent = msg['content'][0];
      if (firstContent['text'] != null) {
        text = firstContent['text'] as String;
      }
    } else if (msg['type'] == 'text' && msg['data'] != null) {
      text = msg['data'] as String;
    }

    if (text != null && text.isNotEmpty) {
      _handleInterviewerText(text);
    }
  }

  void _onWebSocketError(Object error) {
    if (!mounted) return;
    setState(() {
      _state = InterviewState.error;
      _errorMessage = 'Connection error: $error';
    });
  }

  void _onWebSocketDone() {
    if (!mounted) return;
    if (_state == InterviewState.inProgress) {
      setState(() {
        _state = InterviewState.error;
        _errorMessage = 'Connection closed unexpectedly';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _requestMicPermission()) return;

    try {
      final tempDir = Directory.systemTemp;
      _recordingPath = '${tempDir.path}/interview_answer_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null) return;

      setState(() => _isRecording = false);

      // Read recorded file and send to WebSocket
      final file = File(path);
      final bytes = await file.readAsBytes();
      _sendAudioToGemini(bytes);

      // Clean up
      await file.delete();
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<bool> _requestMicPermission() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final status = await Permission.microphone.request();
      return status.isGranted;
    }
    return true;
  }

  void _sendAudioToGemini(List<int> audioBytes) {
    if (_channel == null) return;

    // Send as binary message
    _channel!.sink.add(audioBytes);
  }

  void _playAudio(List<int> audioBytes) async {
    if (_isPlaying) return;

    try {
      setState(() => _isPlaying = true);
      final tempFile = File('${Directory.systemTemp.path}/gemini_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(audioBytes);
      
      await _player.setFilePath(tempFile.path);
      await _player.play();
      
      // Wait for completion using playerStateStream
      await _player.playerStateStream
          .where((state) => state.processingState == ProcessingState.completed)
          .first;
      
      await tempFile.delete();
    } catch (e) {
      debugPrint('Audio playback error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _completeInterview() async {
    if (_sessionId == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final idToken = await user.getIdToken(true);

      // For now, use a placeholder score - in production this would come from
      // the final evaluation message from Gemini Live
      await AuthApiService.completeInterview(
        idToken: idToken!,
        sessionId: _sessionId!,
        overallScore: 75, // Will be replaced by actual evaluation
        summary: 'Interview completed via Gemini Live',
      );

      AppState.instance.recordInterviewCompleted();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview completed successfully!')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to complete interview: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  onPressed: _state == InterviewState.inProgress ? null : () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
              ],

              Text('Mock interview', style: AppTextStyles.headline),
              const SizedBox(height: 16),

              _buildStateContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case InterviewState.checkingStatus:
        return _buildLoading('Checking interview readiness...');

      case InterviewState.notReady:
        return _buildNotReady();

      case InterviewState.readyToStart:
        return _buildReadyToStart();

      case InterviewState.connecting:
        return _buildLoading('Connecting to interviewer...');

      case InterviewState.inProgress:
        return _buildInProgress();

      case InterviewState.completed:
        return _buildCompleted();

      case InterviewState.error:
        return _buildError();
    }
  }

  Widget _buildLoading(String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.blue),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _buildNotReady() {
    final missing = _statusData?['missingRequirements'] as Map<String, dynamic>? ?? {};
    final List<String> issues = [];
    if (missing['careerGoal'] == true) issues.add('Set a career goal in your profile');
    if (missing['resumeAnalysis'] == true) issues.add('Complete a resume analysis first');
    if (missing['dailyLimitReached'] == true) issues.add('Daily limit reached (2/day). Try again tomorrow.');

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Not ready for interview', style: AppTextStyles.title),
            const SizedBox(height: 8),
            ...issues.map((issue) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('• $issue', style: AppTextStyles.body, textAlign: TextAlign.center),
            )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkStatus,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyToStart() {
    final attemptsUsed = _statusData?['attemptsUsed'] ?? 0;
    final attemptsRemaining = _statusData?['attemptsRemaining'] ?? 2;

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded, size: 48, color: AppColors.blue),
            ),
            const SizedBox(height: 24),
            Text('Ready for Interview', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              'Attempt ${attemptsUsed + 1} of 2 today',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              '$attemptsRemaining attempt${attemptsRemaining == 1 ? '' : 's'} remaining today',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Start Interview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _startInterview,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgress() {
    return Expanded(
      child: Column(
        children: [
          // Progress
          Row(
            children: [
              Text(
                'Question $_questionCount of $_maxQuestions',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: _questionCount / _maxQuestions,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question display
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Text(
                  '"$_currentQuestion"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recording button
          Center(
            child: GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.danger : AppColors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? AppColors.danger : AppColors.blue).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    key: ValueKey(_isRecording),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _isRecording
                  ? 'Recording... tap to send'
                  : _isPlaying
                      ? 'Interviewer speaking...'
                      : 'Tap to record your answer',
              style: AppTextStyles.caption.copyWith(
                color: _isRecording ? AppColors.danger : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Interview Complete!', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(_currentQuestion, style: AppTextStyles.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error', style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _checkStatus, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}