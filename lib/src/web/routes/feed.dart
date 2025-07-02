import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../../services/blog_scraper.dart';
import '../../services/atom_feed_generator.dart';

class RouteFeed extends Route {
  @override
  Future<bool> handleCall(Session session, HttpRequest request) async {
    if (request.method != 'GET') {
      return false;
    }

    try {
      // Scrape blog posts
      final scraper = BlogScraper();
      final posts = await scraper.scrapeBlogPosts();

      // Generate ATOM feed
      final generator = AtomFeedGenerator();
      final atomFeed = generator.generateAtomFeed(posts);

      // Set response headers
      request.response.headers.contentType =
          ContentType('application', 'atom+xml', charset: 'utf-8');
      request.response.headers
          .add('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET');

      // Write the ATOM feed
      request.response.write(atomFeed);
      await request.response.close();

      return true;
    } catch (e) {
      // Log error and return 500
      session.log('Error generating feed: $e', level: LogLevel.error);

      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.text;
      request.response.write('Error generating feed: $e');
      await request.response.close();

      return true;
    }
  }
}
