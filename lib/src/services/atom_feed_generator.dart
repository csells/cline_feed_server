import 'package:xml/xml.dart';
import 'blog_scraper.dart';

class AtomFeedGenerator {
  static const String _feedTitle = 'Cline Blog';
  static const String _feedSubtitle = 'Latest posts from the Cline AI coding assistant blog';
  static const String _feedUrl = 'https://cline.bot/blog';
  static const String _feedId = 'https://cline.bot/blog/feed.xml';
  static const String _authorName = 'Cline Team';
  static const String _authorEmail = 'support@cline.bot';
  static const String _authorUri = 'https://cline.bot';

  String generateAtomFeed(List<BlogPost> posts) {
    final builder = XmlBuilder();
    
    // XML declaration
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    
    // Feed element with namespace
    builder.element('feed', nest: () {
      builder.attribute('xmlns', 'http://www.w3.org/2005/Atom');
      
      // Feed metadata
      builder.element('title', nest: _feedTitle);
      builder.element('subtitle', nest: _feedSubtitle);
      builder.element('link', nest: () {
        builder.attribute('href', _feedUrl);
        builder.attribute('rel', 'alternate');
        builder.attribute('type', 'text/html');
      });
      builder.element('link', nest: () {
        builder.attribute('href', _feedId);
        builder.attribute('rel', 'self');
        builder.attribute('type', 'application/atom+xml');
      });
      builder.element('id', nest: _feedId);
      
      // Updated timestamp (latest post date or current time)
      final latestDate = posts.isNotEmpty 
          ? posts.first.publishDate 
          : DateTime.now();
      builder.element('updated', nest: _formatAtomDateTime(latestDate));
      
      // Feed author
      builder.element('author', nest: () {
        builder.element('name', nest: _authorName);
        builder.element('email', nest: _authorEmail);
        builder.element('uri', nest: _authorUri);
      });
      
      // Generator
      builder.element('generator', nest: () {
        builder.attribute('uri', 'https://github.com/serverpod/serverpod');
        builder.attribute('version', '2.9.1');
        builder.text('Serverpod');
      });
      
      // Rights
      builder.element('rights', nest: '© 2025 Cline Bot Inc. All rights reserved.');
      
      // Icon and logo
      builder.element('icon', nest: 'https://cline.bot/assets/icons/favicon-32x32.png');
      builder.element('logo', nest: 'https://cline.bot/assets/icons/favicon-256x256.png');
      
      // Entries
      for (final post in posts) {
        _addEntry(builder, post);
      }
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }

  void _addEntry(XmlBuilder builder, BlogPost post) {
    builder.element('entry', nest: () {
      // Entry ID (should be permanent and unique)
      builder.element('id', nest: post.url);
      
      // Title
      builder.element('title', nest: () {
        builder.attribute('type', 'text');
        builder.text(post.title);
      });
      
      // Link
      builder.element('link', nest: () {
        builder.attribute('href', post.url);
        builder.attribute('rel', 'alternate');
        builder.attribute('type', 'text/html');
      });
      
      // Published date
      builder.element('published', nest: _formatAtomDateTime(post.publishDate));
      
      // Updated date (same as published for blog posts)
      builder.element('updated', nest: _formatAtomDateTime(post.publishDate));
      
      // Author
      builder.element('author', nest: () {
        builder.element('name', nest: post.author);
        builder.element('uri', nest: _authorUri);
      });
      
      // Summary/excerpt
      builder.element('summary', nest: () {
        builder.attribute('type', 'text');
        builder.text(post.excerpt);
      });
      
      // Content (using the excerpt as content for now)
      builder.element('content', nest: () {
        builder.attribute('type', 'html');
        builder.text(_formatHtmlContent(post));
      });
      
      // Categories (generic for now)
      builder.element('category', nest: () {
        builder.attribute('term', 'blog');
        builder.attribute('label', 'Blog');
      });
      builder.element('category', nest: () {
        builder.attribute('term', 'ai');
        builder.attribute('label', 'AI');
      });
      builder.element('category', nest: () {
        builder.attribute('term', 'coding');
        builder.attribute('label', 'Coding');
      });
    });
  }

  String _formatAtomDateTime(DateTime dateTime) {
    // RFC 3339 format as required by Atom
    return dateTime.toUtc().toIso8601String();
  }

  String _formatHtmlContent(BlogPost post) {
    // Use full content if available, otherwise fall back to excerpt
    final content = post.fullContent.isNotEmpty ? post.fullContent : post.excerpt;
    
    // If fullContent exists, it's already HTML so don't escape it
    // If using excerpt, it's plain text so escape it
    final formattedContent = post.fullContent.isNotEmpty 
        ? content // Already HTML
        : _escapeHtml(content); // Plain text excerpt
    
    return '''
    <div>
      $formattedContent
      <p><a href="${_escapeHtml(post.url)}">Read original post →</a></p>
    </div>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}
