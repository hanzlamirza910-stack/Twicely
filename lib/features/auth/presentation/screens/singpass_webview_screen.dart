import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SingpassWebViewScreen extends StatefulWidget {
  final String authorizationUrl;

  const SingpassWebViewScreen({
    super.key,
    required this.authorizationUrl,
  });

  @override
  State<SingpassWebViewScreen> createState() => _SingpassWebViewScreenState();
}

class _SingpassWebViewScreenState extends State<SingpassWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    final userAgent = Platform.isAndroid
        ? "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36"
        : "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkRedirect(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkRedirect(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (_checkRedirect(url)) {
              return NavigationDecision.prevent;
            }

            // Handle custom URI schemes (like singpassmobile://, intent://, etc.)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              try {
                final uri = Uri.parse(url);
                launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Error launching custom scheme: $e');
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  bool _checkRedirect(String url) {
    debugPrint('[Singpass WebView Navigation]: $url');
    if (url.contains('code=') && url.contains('state=')) {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      if (code != null && state != null) {
        Navigator.of(context).pop({'code': code, 'state': state});
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'singpass',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31A22)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
