import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SurveillancePage extends StatefulWidget {
  final String sessionId;
  final String expectedOtp;

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
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isAuthenticated = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  void _connectToWebSocket() {
    String wsUrl = "ws://127.0.0.1:8000/ws/surveillance/${widget.sessionId}/";
    debugPrint("Connecting to WebSocket: $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (message) async {
          debugPrint("Received WebSocket message: $message");
          Map<String, dynamic> data = jsonDecode(message);

          switch (data['type']) {
            case 'offer':
              await _handleOffer(data);
              break;
            case 'candidate':
              await _handleCandidate(data['candidate']);
              break;
            default:
              debugPrint("Unknown message type: ${data['type']}");
          }
        },
        onError: (error) {
          debugPrint("WebSocket Error: $error");
          setState(() => _isConnected = false);
        },
        onDone: () {
          debugPrint("WebSocket Closed");
          setState(() => _isConnected = false);
        },
      );

      setState(() => _isConnected = true);
      _initializePeerConnection();
    } catch (e) {
      debugPrint("WebSocket connection error: $e");
      setState(() => _isConnected = false);
    }
  }

  Future<void> _initializePeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"}
      ],
      "sdpSemantics": "unified-plan",
      "enableDtlsSrtp": true,
    };

    try {
      _peerConnection = await createPeerConnection(configuration);
      debugPrint("PeerConnection created successfully!");

      // Handle remote track
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint("Received track event: ${event.track.kind}");

        if (event.streams.isNotEmpty) {
          debugPrint("Setting stream to renderer");
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
          });
        }
      };

      // Handle connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint("Connection state changed to: $state");
        setState(() {
          _isConnected =
              state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
        });
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint("ICE Connection state: $state");
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          debugPrint("Sending ICE candidate");
          _channel?.sink.add(jsonEncode({
            "type": "candidate",
            "candidate": candidate.toMap(),
          }));
        }
      };
    } catch (e) {
      debugPrint("Error initializing PeerConnection: $e");
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      if (_peerConnection == null) {
        await _initializePeerConnection();
      }

      debugPrint("Setting remote description from offer");
      RTCSessionDescription description = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );

      await _peerConnection?.setRemoteDescription(description);
      debugPrint("Remote description set");
      final answerOptions = <String, dynamic>{
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      };

      // Create answer
      RTCSessionDescription answer =
          await _peerConnection!.createAnswer(answerOptions);
      await _peerConnection!.setLocalDescription(answer);
      debugPrint("Local description (answer) set");

      _channel?.sink.add(jsonEncode({
        "type": "answer",
        "answer": answer.toMap(),
      }));
    } catch (e) {
      debugPrint("Error handling offer: $e");
    }
  }

  Future<void> _handleCandidate(Map<String, dynamic> candidateData) async {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
      debugPrint("Added ICE candidate");
    } catch (e) {
      debugPrint("Error adding ICE candidate: $e");
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpController.text.trim();
    final expectedOtp = widget.expectedOtp.trim();

    debugPrint("Entered OTP: '$enteredOtp'");
    debugPrint("Expected OTP: '$expectedOtp'");

    if (enteredOtp == expectedOtp) {
      setState(() {
        _isAuthenticated = true;
      });
      _connectToWebSocket();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
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
                    child: RTCVideoView(
                      _remoteRenderer,
                      mirror: false,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _peerConnection?.close();
                            _channel?.sink.close();
                            setState(() {
                              _isAuthenticated = false;
                              _isConnected = false;
                              _otpController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                          ),
                          child: const Text(
                            'End Surveillance',
                            style: TextStyle(fontSize: 18),
                          ),
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
                        vertical: 16,
                        horizontal: 32,
                      ),
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
