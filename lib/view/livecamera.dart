import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({Key? key}) : super(key: key);

  @override
  _LiveCameraPageState createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (_cameraController.value.isInitialized &&
        !_cameraController.value.isRecordingVideo) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/live_recording_${DateTime.now().millisecondsSinceEpoch}.mp4';

        await _cameraController.startVideoRecording();
        debugPrint("Recording started and saving to: $filePath");
        setState(() {
          _isRecording = true;
        });
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

        // Optionally, you can show a Snackbar or alert with the saved file path
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
      appBar: AppBar(
        title: const Text('Live Camera'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // Camera is ready
                return CameraPreview(_cameraController);
              } else {
                // Camera is still loading
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            bottom: 20,
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
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red.withOpacity(0.7)
                        : Colors.white,
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
    );
  }
}
