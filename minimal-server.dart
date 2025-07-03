import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'lib/src/web/routes/root.dart';
import 'lib/src/web/routes/feed.dart';
import 'lib/src/services/blog_scraper.dart';

// Minimal server without the problematic generated code
void main(List<String> args) async {
  // Initialize blog post cache before starting server
  final scraper = BlogScraper();
  await scraper.initializeCache(true); // Enable verbose logging during startup

  // Create a basic Serverpod instance without generated endpoints
  final pod = Serverpod(
    args,
    // Empty protocol to avoid generated code issues
    Protocol(),
    // Empty endpoints to avoid generated code issues  
    Endpoints(),
  );

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

// Empty Protocol class to avoid generated code
class Protocol extends SerializationManager {
  Protocol._();
  static final Protocol _instance = Protocol._();
  factory Protocol() => _instance;
}

// Empty Endpoints class to avoid generated code
class Endpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Serverpod serverpod) {
    // No endpoints needed for our simple feed server
  }
}