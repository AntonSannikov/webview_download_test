import 'package:flutter/material.dart';
import 'package:webview_test/screen_one.dart';

class WebViewApp extends StatefulWidget {
  const WebViewApp({Key? key}) : super(key: key);

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Custom In-App Browser"),
        ),
        body: ListView(
          children: generateFakePosts(),
        ));
  }

  List<Widget> generateFakePosts() {
    final posts = <Widget>[];
    for (var i = 0; i < 15; i++) {
      posts.add(Card(
          child: ListTile(
        title: Text('Post title ${i + 1}'),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            "https://picsum.photos/150?random=$i",
          ),
        ),
        subtitle: Text('Subtitle ${i + 1}'),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return const CustomInAppBrowser(
                url: "https://github.com/flutter",
              );
            },
          ));
        },
      )));
    }
    return posts;
  }
}
