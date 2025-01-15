import 'package:flutter/material.dart';
import 'surveillance_page.dart'; // Import the SurveillancePage
import 'livecamera.dart'; // Import the LiveCameraPage

class AddPage extends StatelessWidget {
  const AddPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Options'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
      ),
      body: Center(
        // Center the Column
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Align column height to its content
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center buttons horizontally
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SurveillancePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
                ),
                child: const Text(
                  'Surveillance',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LiveCameraPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
                ),
                child: const Text(
                  'Live Camera',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
