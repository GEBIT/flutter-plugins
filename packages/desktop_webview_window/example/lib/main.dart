import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  debugPrint('args: $args');
  WidgetsFlutterBinding.ensureInitialized();
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  await windowManager.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController(
    text: 'https://example.com',
  );
  bool? _webviewAvailable;

  @override
  void initState() {
    super.initState();
    WebviewWindow.isWebviewAvailable().then((value) {
      setState(() {
        _webviewAvailable = value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            IconButton(
              onPressed: () async {
                final webview = await WebviewWindow.create(
                  configuration: CreateConfiguration(
                    windowHeight: 1280,
                    windowWidth: 720,
                    title: "ExampleTestWindow",
                    titleBarTopPadding: Platform.isMacOS ? 20 : 0,
                    userDataFolderWindows: await _getWebViewPath(),
                  ),
                );

                webview
                  ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
                  ..launch("http://localhost:3000/test.html");
              },
              icon: const Icon(Icons.bug_report),
            )
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(controller: _controller),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _webviewAvailable != true ? null : _onTap,
                  child: const Text('Open'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await WebviewWindow.clearAll(
                      userDataFolderWindows: await _getWebViewPath(),
                    );
                    debugPrint('clear complete');
                  },
                  child: const Text('Clear all'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap() async {
    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        userDataFolderWindows: await _getWebViewPath(),
        titleBarTopPadding: Platform.isMacOS ? 20 : 0,
      ),
    );

    webview
      ..setBrightness(Brightness.dark)
      ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
      ..launch(_controller.text)
      ..setOnUrlRequestCallback((url) {
        debugPrint('url: $url');
        final uri = Uri.parse(url);
        if (uri.path == '/login_success') {
          debugPrint('login success. token: ${uri.queryParameters['token']}');
          webview.close();
        }
        // grant navigation request
        return true;
      })
      ..onClose.whenComplete(() {
        debugPrint("on close");
      });
  }
}

Future<String> _getWebViewPath() async {
  final document = await getApplicationDocumentsDirectory();
  return p.join(
    document.path,
    'desktop_webview_window',
  );
}
