import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:intl/intl.dart';

class BlogPost {
  final String title;
  final String url;
  final String excerpt;
  final String fullContent;
  final DateTime publishDate;
  final String author;

  BlogPost({
    required this.title,
    required this.url,
    required this.excerpt,
    required this.fullContent,
    required this.publishDate,
    required this.author,
  });
}

class BlogScraper {
  static const String _baseUrl = 'https://cline.bot';
  static const String _blogUrl = '$_baseUrl/blog';
  
  // In-memory cache
  final Map<String, BlogPost> _cache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheUpdateInterval = Duration(hours: 1);
  
  // Singleton pattern
  static final BlogScraper _instance = BlogScraper._internal();
  factory BlogScraper() => _instance;
  BlogScraper._internal();

  /// Initialize the cache on startup with full content
  Future<void> initializeCache() async {
    print('Initializing blog post cache...');
    try {
      await _updateCache(isInitialLoad: true);
      print('Cache initialization completed successfully with ${_cache.length} posts');
    } catch (e) {
      print('Failed to initialize cache: $e');
      rethrow;
    }
  }

  /// Get cached posts, updating cache if needed
  Future<List<BlogPost>> scrapeBlogPosts() async {
    // Check if cache needs updating (hourly)
    final now = DateTime.now();
    if (_lastCacheUpdate == null || 
        now.difference(_lastCacheUpdate!).compareTo(_cacheUpdateInterval) > 0) {
      try {
        await _updateCache();
      } catch (e) {
        print('Error updating cache: $e');
        // Continue with existing cache
      }
    }

    // Return cached posts sorted by publish date (newest first)
    final posts = _cache.values.toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    
    return posts.take(10).toList();
  }

  /// Update cache with new posts only
  Future<void> _updateCache({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      print('Fetching blog post list...');
    }
    
    try {
      final response = await http.get(
        Uri.parse(_blogUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to fetch blog page: ${response.statusCode}');
      }

      // Handle encoding properly
      String htmlContent;
      try {
        htmlContent = utf8.decode(response.bodyBytes);
      } catch (e) {
        htmlContent = response.body;
      }

      await _parseAndCachePosts(htmlContent, isInitialLoad: isInitialLoad);
      _lastCacheUpdate = DateTime.now();
      
      if (!isInitialLoad) {
        print('Cache updated: ${_cache.length} total posts');
      }
    } catch (e) {
      if (isInitialLoad) {
        print('Error during initial cache load: $e');
      }
      rethrow;
    }
  }

  Future<void> _parseAndCachePosts(String htmlContent, {bool isInitialLoad = false}) async {
    final document = html_parser.parse(htmlContent);
    final foundPosts = <BlogPost>[];

    // Look for blog post articles or cards
    final articleElements = document.querySelectorAll('article, .post, .blog-post, [class*="post"], [class*="article"]');
    
    if (articleElements.isEmpty) {
      // If no standard article elements found, look for links that might be blog posts
      final linkElements = document.querySelectorAll('a[href*="/blog/"]');
      for (final link in linkElements) {
        final href = link.attributes['href'];
        if (href != null && href != '/blog' && href != '/blog/') {
          final url = _resolveUrl(href);
          
          // Skip if already cached
          if (_cache.containsKey(url)) {
            if (isInitialLoad) {
              print('Skipping cached post: ${link.text.trim()}');
            }
            continue;
          }
          
          if (isInitialLoad) {
            print('Processing new post: ${link.text.trim()}');
          }
          
          final post = await _extractPostFromLink(link, href);
          if (post != null) {
            foundPosts.add(post);
          }
        }
      }
    } else {
      // Process standard article elements
      int processed = 0;
      for (final article in articleElements) {
        // Try to find link to determine URL
        final linkElement = article.querySelector('a[href]');
        final href = linkElement?.attributes['href'];
        if (href != null) {
          final url = _resolveUrl(href);
          
          // Skip if already cached
          if (_cache.containsKey(url)) {
            if (isInitialLoad) {
              final titleElement = article.querySelector('h1, h2, h3, h4, .title, [class*="title"]');
              final title = titleElement?.text.trim() ?? 'Untitled Post';
              print('Skipping cached post: $title');
            }
            continue;
          }
        }
        
        if (isInitialLoad) {
          processed++;
          final titleElement = article.querySelector('h1, h2, h3, h4, .title, [class*="title"]');
          final title = titleElement?.text.trim() ?? 'Untitled Post';
          print('Processing new post ($processed): $title');
        }
        
        final post = await _extractPostFromArticle(article);
        if (post != null) {
          foundPosts.add(post);
        }
      }
    }

    // Add new posts to cache
    for (final post in foundPosts) {
      _cache[post.url] = post;
    }
    
    if (isInitialLoad) {
      print('Added ${foundPosts.length} new posts to cache');
    } else if (foundPosts.isNotEmpty) {
      print('Found ${foundPosts.length} new posts');
    }
  }

  Future<BlogPost?> _extractPostFromArticle(Element article) async {
    try {
      // Try to find title
      final titleElement = article.querySelector('h1, h2, h3, h4, .title, [class*="title"]');
      final title = titleElement?.text.trim() ?? 'Untitled Post';

      // Try to find link
      final linkElement = article.querySelector('a[href]') ?? titleElement?.querySelector('a[href]');
      final href = linkElement?.attributes['href'];
      if (href == null) return null;

      final url = _resolveUrl(href);

      // Try to find excerpt
      final excerptElement = article.querySelector('p, .excerpt, .summary, [class*="excerpt"], [class*="summary"]');
      final excerpt = excerptElement?.text.trim() ?? 'No excerpt available';

      // Try to find date
      final dateElement = article.querySelector('time, .date, [class*="date"], [datetime]');
      final publishDate = _parseDate(dateElement);

      // Try to find author
      final authorElement = article.querySelector('.author, [class*="author"], .by, [class*="by"]');
      final author = authorElement?.text.trim() ?? 'Cline Team';

      // Fetch full content from the article URL
      final fullContent = await _fetchFullContent(url);

      return BlogPost(
        title: title,
        url: url,
        excerpt: _truncateExcerpt(excerpt),
        fullContent: fullContent,
        publishDate: publishDate,
        author: author,
      );
    } catch (e) {
      print('Error extracting post from article: $e');
      return null;
    }
  }

  Future<BlogPost?> _extractPostFromLink(Element link, String href) async {
    try {
      final title = link.text.trim();
      if (title.isEmpty) return null;

      final url = _resolveUrl(href);

      // Look for excerpt in nearby elements
      final parent = link.parent;
      final excerpt = parent?.querySelector('p')?.text.trim() ?? 'No excerpt available';

      // Look for date in nearby elements
      final dateElement = parent?.querySelector('time, .date, [class*="date"]');
      final publishDate = _parseDate(dateElement);

      // Fetch full content from the article URL
      final fullContent = await _fetchFullContent(url);

      return BlogPost(
        title: title,
        url: url,
        excerpt: _truncateExcerpt(excerpt),
        fullContent: fullContent,
        publishDate: publishDate,
        author: 'Cline Team',
      );
    } catch (e) {
      print('Error extracting post from link: $e');
      return null;
    }
  }

  String _resolveUrl(String href) {
    if (href.startsWith('http')) {
      return href;
    } else if (href.startsWith('/')) {
      return '$_baseUrl$href';
    } else {
      return '$_blogUrl/$href';
    }
  }

  DateTime _parseDate(Element? dateElement) {
    if (dateElement == null) return DateTime.now();

    // Try datetime attribute first
    final datetime = dateElement.attributes['datetime'];
    if (datetime != null) {
      try {
        return DateTime.parse(datetime);
      } catch (e) {
        // Continue to text parsing
      }
    }

    // Try parsing text content
    final dateText = dateElement.text.trim();
    if (dateText.isNotEmpty) {
      try {
        // Try various date formats
        final formats = [
          'yyyy-MM-dd',
          'MM/dd/yyyy',
          'dd/MM/yyyy',
          'MMM dd, yyyy',
          'MMMM dd, yyyy',
          'dd MMM yyyy',
          'dd MMMM yyyy',
        ];

        for (final format in formats) {
          try {
            return DateFormat(format).parse(dateText);
          } catch (e) {
            // Continue to next format
          }
        }
      } catch (e) {
        // Fall back to current date
      }
    }

    return DateTime.now();
  }

  String _truncateExcerpt(String text) {
    if (text.length <= 200) return text;
    final truncated = text.substring(0, 200);
    final lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace > 150) {
      return '${truncated.substring(0, lastSpace)}...';
    }
    return '$truncated...';
  }

  Future<String> _fetchFullContent(String articleUrl) async {
    try {
      final response = await http.get(
        Uri.parse(articleUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (response.statusCode != 200) {
        print('Failed to fetch article content from $articleUrl: ${response.statusCode}');
        return 'Failed to load full content.';
      }

      // Handle encoding properly
      String htmlContent;
      try {
        htmlContent = utf8.decode(response.bodyBytes);
      } catch (e) {
        htmlContent = response.body;
      }

      final document = html_parser.parse(htmlContent);
      
      // Try different selectors to find the main content
      final contentSelectors = [
        'article .prose', // Common blog content wrapper
        'article main',
        'article .content',
        'article .post-content',
        'article .entry-content',
        '.content .prose',
        '.post-content',
        '.entry-content',
        'main article',
        'article', // Fallback to whole article
      ];

      Element? contentElement;
      for (final selector in contentSelectors) {
        contentElement = document.querySelector(selector);
        if (contentElement != null) break;
      }

      if (contentElement == null) {
        return 'Could not extract full content from the article.';
      }

      // Remove unwanted elements like navigation, ads, etc.
      final unwantedSelectors = [
        'nav', '.navigation', '.nav',
        '.sidebar', '.aside',
        '.advertisement', '.ads', '.ad',
        '.social-share', '.share',
        '.comments', '.comment',
        '.related-posts', '.related',
        'script', 'style',
        '.header', '.footer',
      ];

      for (final selector in unwantedSelectors) {
        contentElement.querySelectorAll(selector).forEach((el) => el.remove());
      }

      // Extract HTML content while preserving structure
      String content = contentElement.innerHtml;
      
      // Clean up excessive whitespace but preserve HTML structure
      content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n'); // Collapse multiple empty lines
      content = content.trim();
      
      // If content is too short, something might be wrong
      if (content.length < 100) {
        return 'Could not extract meaningful content from the article.';
      }

      return content;
    } catch (e) {
      print('Error fetching full content from $articleUrl: $e');
      return 'Error loading full content.';
    }
  }
}
