import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter & Express Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String data = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fetch data from your Express API
  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://localhost:1060/'));

    if (response.statusCode == 200) {
      setState(() {
        data = response.body; // Show the response from the backend
      });
    } else {
      setState(() {
        data = 'Failed to load data from backend';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter & Express Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Data from backend:',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              data,  // Show fetched data
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchData,  // Fetch data again when button is pressed
        tooltip: 'Reload Data',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
