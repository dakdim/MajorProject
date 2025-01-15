import 'package:flutter/material.dart';
// import 'livecamera.dart';

class SurveillancePage extends StatelessWidget {
  const SurveillancePage({Key? key}) : super(key: key);

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
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
                hintText: 'Enter your OTP here',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP Submitted')),
                );
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) => const LiveCameraPage()),
                // );
                // You can add further navigation or functionality here
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
