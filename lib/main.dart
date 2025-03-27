import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'dart:io';

void main() {
  runApp(ExamApp());
}

void _checkGuidedAccess(BuildContext context) async {
  if (Platform.isIOS) {
    final mode = await getKioskMode(); // Cek status Guided Access
    if (mode == KioskMode.disabled) {
      _showGuidedAccessAlert(context);
    }
  }
}

void _showGuidedAccessAlert(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text("Aktifkan Guided Access"),
      content: Text("Untuk mencegah siswa keluar dari aplikasi, aktifkan 'Guided Access':\n\n"
          "1. Buka **Settings** → **Accessibility**.\n"
          "2. Pilih **Guided Access** dan aktifkan.\n"
          "3. Saat ujian dimulai, tekan **tombol samping 3x** untuk mengunci aplikasi."),
      actions: [
        TextButton(
          child: Text("OK"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExamWebView(url: examLinks[index]['url']!),
                  ),
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
  late final WebViewController _controller; // Deklarasi _controller

  ExamWebView({required this.url});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Blokir tombol back Android
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (Platform.isIOS && details.primaryDelta! > 20) {
            // Cegah swipe-back di iOS
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }

  @override
  _ExamWebViewState createState() => _ExamWebViewState();
}

class _ExamWebViewState extends State<ExamWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));

    _enableKioskMode();
    _checkGuidedAccess(context);
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

  @override
  void dispose() {
    _disableKioskMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
