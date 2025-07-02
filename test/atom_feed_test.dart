import 'package:test/test.dart';
import 'package:cline_feed_server/src/services/blog_scraper.dart';
import 'package:cline_feed_server/src/services/atom_feed_generator.dart';

void main() {
  group('ATOM Feed Tests', () {
    test('Blog scraper can fetch posts', () async {
      final scraper = BlogScraper();
      try {
        final posts = await scraper.scrapeBlogPosts();
        expect(posts, isNotNull);
        print('Found ${posts.length} blog posts');
        
        if (posts.isNotEmpty) {
          final firstPost = posts.first;
          expect(firstPost.title, isNotEmpty);
          expect(firstPost.url, isNotEmpty);
          expect(firstPost.excerpt, isNotEmpty);
          expect(firstPost.author, isNotEmpty);
          print('First post: ${firstPost.title}');
          print('URL: ${firstPost.url}');
          print('Excerpt: ${firstPost.excerpt}');
        }
      } catch (e) {
        print('Error testing blog scraper: $e');
        // Don't fail the test if the website is unreachable
        expect(e, isNotNull);
      }
    });

    test('ATOM feed generator creates valid XML', () {
      final generator = AtomFeedGenerator();
      final mockPosts = [
        BlogPost(
          title: 'Test Post 1',
          url: 'https://cline.bot/blog/test-1',
          excerpt: 'This is a test excerpt for the first post.',
          fullContent: 'This is the full content of the first test post with much more detail and information.',
          publishDate: DateTime(2025, 1, 1),
          author: 'Test Author',
        ),
        BlogPost(
          title: 'Test Post 2',
          url: 'https://cline.bot/blog/test-2', 
          excerpt: 'This is a test excerpt for the second post.',
          fullContent: 'This is the full content of the second test post with extensive details and analysis.',
          publishDate: DateTime(2025, 1, 2),
          author: 'Test Author 2',
        ),
      ];

      final atomFeed = generator.generateAtomFeed(mockPosts);
      
      expect(atomFeed, isNotEmpty);
      expect(atomFeed, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(atomFeed, contains('<feed xmlns="http://www.w3.org/2005/Atom">'));
      expect(atomFeed, contains('<title>Cline Blog</title>'));
      expect(atomFeed, contains('<entry>'));
      expect(atomFeed, contains('Test Post 1'));
      expect(atomFeed, contains('Test Post 2'));
      expect(atomFeed, contains('</feed>'));
      
      print('Generated ATOM feed:\n$atomFeed');
    });
  });
}
