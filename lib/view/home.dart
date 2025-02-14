import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:myapp/view/add.dart';
import 'notification_page.dart';
import 'storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text('', style: TextStyle(fontSize: 20))),
    NotificationPage(),
    AddPage(),
    StoragePage(),
  ];

  void _navigateToPage(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _pages[index],
        ),
      ).then((_) {
        // Return to the homepage when popping back
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(198, 160, 206, 1),
        title: const Text('All Eyes On You'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromRGBO(
            198, 160, 206, 0.2), // Background behind the bar
        color: const Color.fromRGBO(198, 160, 206, 1), // Bar color
        buttonBackgroundColor: Colors.white, // Selected item background
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.black),
          Icon(Icons.notifications, size: 30, color: Colors.black),
          Icon(Icons.add, size: 30, color: Colors.black),
          Icon(Icons.storage, size: 30, color: Colors.black),
        ],
        onTap: (index) {
          _navigateToPage(index);
        },
      ),
    );
  }
}
