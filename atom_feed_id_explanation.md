# Unique Item IDs in Generated Atom Feed

## Summary

The unique item IDs for entries in the generated atom feed are calculated using the **URL of each blog post**. This is a simple but effective approach that ensures both uniqueness and permanence.

## Implementation Details

### Location
The ID calculation is implemented in `lib/src/services/atom_feed_generator.dart` within the `_addEntry` method.

### Code Reference
```dart
// Entry ID (should be permanent and unique)
builder.element('id', nest: post.url);
```

### How URLs are Determined

The URLs come from the `BlogPost` class which has a `url` field populated during the scraping process in `blog_scraper.dart`. The URL resolution follows this logic:

1. **Absolute URLs**: If the href starts with "http", it's used as-is
2. **Root-relative URLs**: If the href starts with "/", it's prefixed with `https://cline.bot`
3. **Relative URLs**: Other hrefs are prefixed with `https://cline.bot/blog/`

### URL Resolution Code
```dart
String _resolveUrl(String href) {
  if (href.startsWith('http')) {
    return href;
  } else if (href.startsWith('/')) {
    return '$_baseUrl$href';
  } else {
    return '$_blogUrl/$href';
  }
}
```

## Why URLs Make Good IDs

1. **Uniqueness**: Each blog post has a unique URL
2. **Permanence**: URLs for blog posts typically don't change once published
3. **RFC 4287 Compliance**: The Atom specification recommends using permalinks as IDs
4. **Human Readable**: URLs are meaningful to both humans and machines

## Example

For a blog post with URL `https://cline.bot/blog/introducing-new-features`, the atom feed entry ID would be:
```xml
<id>https://cline.bot/blog/introducing-new-features</id>
```

This approach ensures that each entry in the atom feed has a stable, unique identifier that feed readers can use to track which posts have been read or are new.