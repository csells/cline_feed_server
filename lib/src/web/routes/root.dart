import 'dart:io';

import 'package:serverpod/serverpod.dart';

class RouteRoot extends Route {
  @override
  Future<bool> handleCall(Session session, HttpRequest request) async {
    if (request.method != 'GET') {
      return false;
    }

    try {
      // Serve the index.html file
      final file = File('web/static/index.html');
      if (await file.exists()) {
        final content = await file.readAsString();

        request.response.headers.contentType = ContentType.html;
        request.response.write(content);
        await request.response.close();

        return true;
      } else {
        // Fallback to a simple HTML response if file doesn't exist
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<!DOCTYPE html>
<html><head><title>Cline Blog Feed Service</title></head>
<body><h1>Feed Service</h1><p>Available feeds:</p>
<ul><li><a href="/feed.xml">/feed.xml</a></li>
<li><a href="/atom.xml">/atom.xml</a></li>
<li><a href="/blog/feed.xml">/blog/feed.xml</a></li></ul></body></html>
        ''');
        await request.response.close();

        return true;
      }
    } catch (e) {
      session.log('Error serving index page: $e', level: LogLevel.error);
      return false;
    }
  }
}
