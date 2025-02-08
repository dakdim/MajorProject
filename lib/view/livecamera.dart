import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({Key? key}) : super(key: key);

  @override
  _LiveCameraPageState createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  String _otp = "";
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _channel.sink.close(status.normalClosure);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.max,
        enableAudio: true,
      );

      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture;

      _generateOTP();
      setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _generateOTP() {
    final random = Random();
    _otp = (100000 + random.nextInt(900000)).toString();
    setState(() {});
    _sendOTPToServer(_otp);
  }

  void _initializeWebSocket() {
    String sessionId = "12345"; // Replace with actual session ID
    String serverUrl = "ws://http://127.0.0.1:50645/ws/live-stream/$sessionId/";

    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

    _channel.stream.listen(
      (message) {
        debugPrint("Received WebSocket message: $message");
      },
      onError: (error) {
        debugPrint("WebSocket error: $error");
      },
      onDone: () {
        debugPrint("WebSocket connection closed.");
      },
    );
  }

  void _sendOTPToServer(String otp) {
    final message = jsonEncode({"type": "otp", "otp": otp});
    _channel.sink.add(message);
  }

  Future<void> _startRecording() async {
    if (_cameraController.value.isInitialized && !_isRecording) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        // ignore: unused_local_variable
        final filePath =
            '${directory.path}/live_recording_${DateTime.now().millisecondsSinceEpoch}.mp4';

        await _cameraController.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
        debugPrint("Recording started...");
        _channel.sink.add(jsonEncode({"type": "start_recording"}));
      } catch (e) {
        debugPrint("Error starting recording: $e");
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController.value.isRecordingVideo) {
      try {
        final XFile videoFile = await _cameraController.stopVideoRecording();
        debugPrint("Recording saved to: ${videoFile.path}");
        setState(() {
          _isRecording = false;
        });

        _channel.sink.add(
            jsonEncode({"type": "stop_recording", "file": videoFile.path}));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video saved to: ${videoFile.path}")),
        );
      } catch (e) {
        debugPrint("Error stopping recording: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_cameraController);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "OTP: $_otp",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else {
                      _startRecording();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      size: 40,
                      color: _isRecording ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
