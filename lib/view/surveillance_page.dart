import 'package:flutter/material.dart';

class SurveillancePage extends StatefulWidget {
  const SurveillancePage({Key? key}) : super(key: key);

  @override
  _SurveillancePageState createState() => _SurveillancePageState();
}

class _SurveillancePageState extends State<SurveillancePage> {
  final TextEditingController _otpController = TextEditingController();
  final String validOtp = "1234"; // Define a valid OTP for comparison

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
      ),
      body: Padding(
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
              onPressed: () {
                if (_otpController.text == validOtp) {
                  // Navigate to the Monitoring Page if OTP is valid
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonitoringPage(),
                    ),
                  );
                } else {
                  // Show an error message if OTP is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid OTP. Please try again.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
      ),
      body: Column(
        children: [
          // Upper box: Placeholder for a photo or other content
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Text(
                  'I LOVE YOU',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
          ),
          // Lower box: Placeholder for description
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Description ',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
