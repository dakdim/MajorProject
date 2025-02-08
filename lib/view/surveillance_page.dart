import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SurveillancePage extends StatefulWidget {
  final String sessionId; // Pass session ID dynamically
  final String expectedOtp; // Expected OTP received from the server

  const SurveillancePage({
    Key? key,
    required this.sessionId,
    required this.expectedOtp,
  }) : super(key: key);

  @override
  _SurveillancePageState createState() => _SurveillancePageState();
}

class _SurveillancePageState extends State<SurveillancePage> {
  final TextEditingController _otpController = TextEditingController();
  WebSocketChannel? _channel;
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _channel?.sink.close();
    super.dispose();
  }

  void _connectToWebSocket() {
    String wsUrl = "ws://127.0.0.1:50645/ws/surveillance/${widget.sessionId}/";

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen((message) async {
        Map<String, dynamic> data = jsonDecode(message);
        debugPrint("Received WebSocket message: $data");

        if (data['type'] == 'offer') {
          await _handleOffer(data['offer']);
        } else if (data['type'] == 'candidate') {
          await _handleCandidate(data['candidate']);
        }
      }, onError: (error) {
        debugPrint("WebSocket Error: $error");
      }, onDone: () {
        debugPrint("WebSocket Closed.");
      });

      _channel!.sink.add(jsonEncode({"type": "viewer_ready"}));
    } catch (e) {
      debugPrint("Error connecting WebSocket: $e");
    }
  }

  Future<void> _initializeWebRTC() async {
    Map<String, dynamic> config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"}
      ]
    };

    try {
      _peerConnection = await createPeerConnection(config);

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
          });
        }
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (_channel != null) {
          _channel!.sink.add(jsonEncode(
              {"type": "candidate", "candidate": candidate.toMap()}));
        }
      };
    } catch (e) {
      debugPrint("Error initializing WebRTC: $e");
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    if (_peerConnection == null) {
      await _initializeWebRTC();
    }

    await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']));
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _channel!.sink
        .add(jsonEncode({"type": "answer", "answer": answer.toMap()}));
  }

  Future<void> _handleCandidate(Map<String, dynamic> candidate) async {
    if (_peerConnection != null) {
      await _peerConnection!.addCandidate(RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex']));
    }
  }

  void _verifyOtp() {
    if (_otpController.text == widget.expectedOtp) {
      setState(() {
        _isAuthenticated = true;
      });
      _connectToWebSocket();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance'),
        backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
      ),
      body: _isAuthenticated
          ? Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.black,
                    child: RTCVideoView(_remoteRenderer, mirror: false),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Live Surveillance Streaming',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'This section provides details about the surveillance feed. '
                          'Ensure your connection is stable for optimal video quality.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Enter the OTP',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'OTP',
                      hintText: 'Enter your OTP here',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
                    ),
                    child: const Text(
                      'Start Surveillance',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
