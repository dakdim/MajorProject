import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
  bool _isStreaming = false;
  String _otp = "";
  WebSocketChannel? _channel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _wsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _stopStream();
    _cameraController.dispose();
    _peerConnection?.dispose();
    _localStream?.dispose();
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

      // Use the back camera by default
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
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
    if (_wsInitialized) return;

    String sessionId = "1YPVzoyZjcNg2IY0"; // Consider making this dynamic
    // Replace with your actual server IP/domain
    String serverUrl = "ws://127.0.0.1:8000/ws/live-stream/$sessionId/";

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _wsInitialized = true;

      // Single listener for the WebSocket stream
      _channel?.stream.listen(
        (message) {
          debugPrint("Received WebSocket message: $message");
          final data = jsonDecode(message);

          if (data["type"] == "otp") {
            setState(() {
              _otp = data["otp"];
            });
          } else if (data["type"] == "answer") {
            _handleAnswer(data);
          } else if (data["type"] == "candidate") {
            _handleIceCandidate(data);
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _wsInitialized = false;
        },
        onDone: () {
          debugPrint("WebSocket connection closed.");
          _wsInitialized = false;
        },
      );

      // Request OTP after connection is established
      Future.delayed(const Duration(seconds: 1), () {
        _channel?.sink.add(jsonEncode({"type": "get_otp"}));
      });
    } catch (e) {
      debugPrint("Failed to connect to WebSocket: $e");
      _wsInitialized = false;
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        data["answer"]["sdp"],
        data["answer"]["type"],
      );
      await _peerConnection?.setRemoteDescription(answer);
      debugPrint("Remote description set successfully");
    } catch (e) {
      debugPrint("Error handling answer: $e");
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        data["candidate"]["candidate"],
        data["candidate"]["sdpMid"],
        data["candidate"]["sdpMLineIndex"],
      );
      await _peerConnection?.addCandidate(candidate);
      debugPrint("Added ICE candidate");
    } catch (e) {
      debugPrint("Error handling ICE candidate: $e");
    }
  }

  Future<void> _initializeWebRTC() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        // Add TURN server configuration if needed
      ],
      "sdpSemantics": "unified-plan",
    };

    try {
      _peerConnection = await createPeerConnection(configuration);
      debugPrint("PeerConnection created");

      // Get local media stream
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': 'environment',
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          }
        }
      };

      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint("Local stream obtained");

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
        debugPrint("Added track: ${track.kind}");
      });

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) return;
        debugPrint("Sending ICE candidate");
        _channel?.sink.add(jsonEncode({
          "type": "candidate",
          "candidate": candidate.toMap(),
        }));
      };

      // Create and send offer
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await _peerConnection!.setLocalDescription(offer);
      debugPrint("Local description set, sending offer");

      _channel?.sink.add(jsonEncode({
        "type": "offer",
        "offer": offer.toMap(),
      }));
    } catch (e) {
      debugPrint("Error initializing WebRTC: $e");
    }
  }

  Future<void> _startStream() async {
    if (!_cameraController.value.isInitialized) {
      debugPrint("Camera not initialized yet.");
      return;
    }

    await _initializeWebRTC();
    setState(() {
      _isStreaming = true;
    });
  }

  Future<void> _stopStream() async {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
    setState(() {
      _isStreaming = false;
    });
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
          if (_isStreaming) {
            _stopStream();
          } else {
            _startStream();
          }
        },
        backgroundColor: _isStreaming ? Colors.red : Colors.blue,
        child: Icon(_isStreaming ? Icons.stop : Icons.videocam),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
