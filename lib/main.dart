import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'dart:io';

void main() {
  runApp(ExamApp());
}

class ExamApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExamHomePage(),
    );
  }
}

class ExamHomePage extends StatelessWidget {
  final List<Map<String, String>> examLinks = [
    {'title': 'Soal Ujian 1', 'url': 'https://forms.gle/example1'},
    {'title': 'Soal Ujian 2', 'url': 'https://forms.gle/example2'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ujian Online')),
      body: ListView.builder(
        itemCount: examLinks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(examLinks[index]['title']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamWebView(url: examLinks[index]['url']!),
                ),
              );
            },
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
    _enableKioskMode();
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
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
