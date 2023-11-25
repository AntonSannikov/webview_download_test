import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgressState {
  final int progress;
  final int contentLength;

  ProgressState(this.progress, this.contentLength);
}

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key});

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;

  final ReceivePort _port = ReceivePort();

  String _url = 'https://unsplash.com/images';
  // String _url = 'https://testfiledownload.com';

  final StreamController progressController = StreamController<ProgressState>();

  @override
  void initState() {
    super.initState();
    _askPermissions();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      // DownloadTaskStatus status = DownloadTaskStatus(data[1]);
      int progress = data[2];
      log('progress: $data');
      progressController.sink.add(ProgressState(progress, 0));
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  Future<void> _askPermissions() async {
    await Permission.notification.request();
  }

  Future<void> _startDownload(DownloadStartRequest downloadRequest) async {
    print('object');
    final externalStorageDir = await getExternalStorageDirectory();
    final taskId = await FlutterDownloader.enqueue(
      url: downloadRequest.url.rawValue,
      savedDir: externalStorageDir!.absolute.path,
      fileName: downloadRequest.suggestedFilename,
      showNotification: true,
      openFileFromNotification: true,
    );

    log('created download task:');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
      child: Column(
        children: [
          Container(
            color: Colors.red,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            height: 60,
            padding: EdgeInsets.all(10),
            child: StreamBuilder(
                stream: progressController.stream,
                builder: (context, snapchot) => (snapchot.data == null)
                    ? SizedBox.shrink()
                    : Text(
                        snapchot.data.progress.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      )),
          ),
          Expanded(
            child: InAppWebView(
              key: _webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(_url)),
              initialSettings:
                  InAppWebViewSettings(transparentBackground: true, safeBrowsingEnabled: true, isFraudulentWebsiteWarningEnabled: true),
              onWebViewCreated: (controller) async {
                _webViewController = controller;
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
                  await controller.startSafeBrowsing();
                }
              },
              onDownloadStartRequest: (controller, downloadStartRequest) {
                _startDownload(downloadStartRequest);
              },
              onLoadStart: (controller, url) {
                print('start $url');
              },
              onLoadStop: (controller, url) async {
                print('stop $url');
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                print('update history $url');
              },
              onTitleChanged: (controller, title) {
                print('title changed $title');
              },
              onProgressChanged: (controller, progress) {
                log('message $progress');
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                if (navigationAction.isForMainFrame &&
                    url != null &&
                    !['http', 'https', 'file', 'chrome', 'data', 'javascript', 'about'].contains(url.scheme)) {
                  if (await canLaunchUrl(url)) {
                    launchUrl(url);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'enter url',
            ),
            onChanged: (value) => _url = value,
          ),
        ],
      ),
    )));
  }
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}
