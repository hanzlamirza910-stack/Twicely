import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
            if (_checkRedirect(request.url)) {
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
