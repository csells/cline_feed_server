import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/src/services/blog_scraper.dart';
import '../lib/src/services/atom_feed_generator.dart';

void main() async {
  // Initialize blog post cache
  print('🚀 Starting Cline Feed Server...');
  final scraper = BlogScraper();
  await scraper.initializeCache(true);

  // Create router
  final router = Router();

  // Root route
  router.get('/', (Request request) {
    return Response.ok('''
<!DOCTYPE html>
<html>
<head>
    <title>Cline Feed Server</title>
</head>
<body>
    <h1>Cline Blog Feed Server</h1>
    <p>This server provides ATOM feeds for the Cline AI blog.</p>
    <p><a href="/atom.xml">ATOM Feed</a></p>
</body>
</html>
''', headers: {'content-type': 'text/html'});
  });

  // ATOM feed route
  router.get('/atom.xml', (Request request) async {
    try {
      // Scrape blog posts
      final posts = await scraper.scrapeBlogPosts();

      // Generate ATOM feed
      final generator = AtomFeedGenerator();
      final atomFeed = generator.generateAtomFeed(posts);

      // Return feed with proper headers
      return Response.ok(
        atomFeed,
        headers: {
          'content-type': 'application/atom+xml; charset=utf-8',
          'cache-control': 'public, max-age=3600',
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'GET',
        },
      );
    } catch (e) {
      print('Error generating feed: $e');
      return Response.internalServerError(
        body: 'Error generating feed: $e',
        headers: {'content-type': 'text/plain'},
      );
    }
  });

  // Start server
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(router, InternetAddress.anyIPv4, port);
  
  print('✅ Cline Feed Server running on http://${server.address.host}:${server.port}');
  print('🔗 ATOM feed available at: http://${server.address.host}:${server.port}/atom.xml');
}