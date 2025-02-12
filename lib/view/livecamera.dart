import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
  String _otp = ""; // Default text before OTP is received
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _channel?.sink.close(status.normalClosure);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No available cameras.");
        return;
      }
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.max,
        enableAudio: true,
      );

      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture;

      debugPrint("Camera initialized successfully.");
      setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _initializeWebSocket() {
    String sessionId = "abcd1234xyz"; // Replace with actual session ID
    String serverUrl = "ws://127.0.0.1:8000/ws/live-stream/$sessionId/";

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      debugPrint("WebSocket connection established.");

      _channel?.stream.listen(
        (message) {
          debugPrint("Received WebSocket message: $message");

          final data = jsonDecode(message);

          if (data["type"] == "otp") {
            setState(() {
              _otp = data["otp"];
            });
            debugPrint("Updated OTP on UI: $_otp");
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
        },
        onDone: () {
          debugPrint("WebSocket connection closed.");
        },
      );

      // Request OTP from backend after connection is established
      Future.delayed(Duration(seconds: 1), () {
        debugPrint("Requesting OTP from backend...");
        _channel?.sink.add(jsonEncode({"type": "get_otp"}));
      });
    } catch (e) {
      debugPrint("Failed to connect to WebSocket: $e");
    }
  }

  Future<void> _startRecording() async {
    if (!_cameraController.value.isInitialized) {
      debugPrint("Camera not initialized yet.");
      return;
    }
    if (_isRecording) {
      debugPrint("Already recording.");
      return;
    }

    try {
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      debugPrint("Recording started...");
      _channel?.sink.add(jsonEncode({"type": "start_recording"}));
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      debugPrint("Not currently recording.");
      return;
    }

    try {
      final XFile videoFile = await _cameraController.stopVideoRecording();
      debugPrint("Recording saved to: ${videoFile.path}");

      setState(() {
        _isRecording = false;
      });

      _channel?.sink.add(
        jsonEncode({"type": "stop_recording", "file": videoFile.path}),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Video saved to: ${videoFile.path}")),
      );
    } catch (e) {
      debugPrint("Error stopping recording: $e");
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isRecording) {
            _stopRecording();
          } else {
            _startRecording();
          }
        },
        backgroundColor: _isRecording ? Colors.red : Colors.blue,
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
