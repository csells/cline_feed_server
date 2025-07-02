import 'package:serverpod/serverpod.dart';

import 'package:cline_feed_server/src/web/routes/root.dart';
import 'package:cline_feed_server/src/web/routes/feed.dart';
import 'package:cline_feed_server/src/services/blog_scraper.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

// This is the starting point of your Serverpod server. In most cases, you will
// only need to make additions to this file if you add future calls,  are
// configuring Relic (Serverpod's web-server), or need custom setup work.

void run(List<String> args) async {
  // Initialize blog post cache before starting server
  print('Starting Cline Feed Server...');
  final scraper = BlogScraper();
  await scraper.initializeCache();
  
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Setup a default page at the web root.
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  
  // Setup ATOM feed route
  pod.webServer.addRoute(RouteFeed(), '/atom.xml');
  
  // Serve all files in the /static directory.
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/css/*',
  );
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/images/*',
  );

  // Start the server.
  await pod.start();
}
