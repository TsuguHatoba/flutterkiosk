import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(ExamApp());
}

class ExamApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black87,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        listTileTheme: ListTileThemeData(iconColor: Colors.white, textColor: Colors.white),
      ),
      home: ExamHomePage(),
    );
  }
}

class ExamHomePage extends StatelessWidget {
  final List<Map<String, String>> examLinks = [
    {'title': 'Soal Ujian 1', 'url': 'https://forms.gle/example1', 'password': '1234'},
    {'title': 'Soal Ujian 2', 'url': 'https://forms.gle/example2', 'password': '5678'},
  ];

  void _promptForPassword(BuildContext context, String correctPassword, String url) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Masukkan Password"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: "Password"),
        ),
        actions: [
          TextButton(
            child: Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () {
              if (passwordController.text == correctPassword) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExamWebView(url: url)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password salah!"), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ujian Online')),
      body: ListView.builder(
        itemCount: examLinks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _promptForPassword(
                  context,
                  examLinks[index]['password']!,
                  examLinks[index]['url']!,
                );
              },
              child: Text(examLinks[index]['title']!),
            ),
          );
        },
      ),
    );
  }
}

class ExamWebView extends StatefulWidget {
  final String url;
  ExamWebView({required this.url});

  @override
  _ExamWebViewState createState() => _ExamWebViewState();
}

class _ExamWebViewState extends State<ExamWebView> {
  late final WebViewController _controller;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  String _batteryLevel = "-";
  String _connectionStatus = "-";
  String _time = "-";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
    _enableKioskMode();
    _updateStatus();
  }

  void _enableKioskMode() async {
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await startKioskMode();
    }
  }

  void _disableKioskMode() async {
    if (Platform.isAndroid) {
      await stopKioskMode();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _updateStatus() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final batteryLevel = await _battery.batteryLevel;
      final connectivityResult = await _connectivity.checkConnectivity();
      final timeNow = DateFormat('HH:mm').format(DateTime.now());
      setState(() {
        _batteryLevel = "$batteryLevel%";
        _connectionStatus = connectivityResult.toString().split(".").last;
        _time = timeNow;
      });
    });
  }

  void _confirmExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi"),
        content: Text("Apakah Anda yakin ingin keluar dari ujian?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Tidak"),
          ),
          TextButton(
            onPressed: () {
              _disableKioskMode();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text("Ya"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disableKioskMode();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Baterai: $_batteryLevel", style: TextStyle(color: Colors.white)),
                Text("WiFi: $_connectionStatus", style: TextStyle(color: Colors.white)),
                Text("Waktu: $_time", style: TextStyle(color: Colors.white)),
                IconButton(
                  icon: Icon(Icons.exit_to_app, color: Colors.red),
                  onPressed: _confirmExit,
                ),
              ],
            ),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
