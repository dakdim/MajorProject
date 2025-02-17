import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  final List<String> notifications = [
    "Unusual activity detected at 10:15 AM",
    "Unusual activity detected at 11:30 AM",
    "Unusual activity detected at 02:45 PM",
  ]; // Example notifications

  NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: const Text('Notifications'),
          // centerTitle: true,
          // backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
          ),
      body: notifications.isNotEmpty
          ? ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(notifications[index]),
                    subtitle: const Text('Tap for more details'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Details for: ${notifications[index]}'),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'No unusual activity detected.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
