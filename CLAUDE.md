# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Serverpod-based Dart server that provides an ATOM feed service for the Cline AI blog. The server scrapes blog posts from https://cline.bot/blog and generates ATOM feeds at multiple endpoints.

## Core Architecture

**Main Components:**
- `lib/server.dart` - Main server configuration with route setup
- `lib/src/services/blog_scraper.dart` - Web scraper for extracting blog posts from cline.bot
- `lib/src/services/atom_feed_generator.dart` - ATOM XML feed generator following RFC 4287
- `lib/src/web/routes/feed.dart` - HTTP route handler for feed endpoints

**Feed Endpoints:**
- `/feed.xml`, `/atom.xml`, `/blog/feed.xml` - All serve the same ATOM feed

**Data Flow:**
1. HTTP request to feed endpoint
2. BlogScraper fetches and parses HTML from cline.bot/blog
3. AtomFeedGenerator creates valid ATOM XML from parsed posts
4. Response served with proper content-type and caching headers

## Development Commands

**Start Development Environment:**
```bash
# Start PostgreSQL and Redis
docker compose up --build --detach

# Start the server
dart bin/main.dart

# Stop services when done
docker compose stop
```

**Testing:**
```bash
# Run all tests
dart test

# Run specific test file
dart test test/atom_feed_test.dart

# Run integration tests only
dart test --tags integration
```

**Code Generation:**
```bash
# Generate Serverpod code (after modifying endpoints/protocol)
serverpod generate
```

## Database & Services

- **PostgreSQL**: Development on port 8090, Test on port 9090
- **Redis**: Development on port 8091, Test on port 9091
- Uses pgvector/pgvector:pg16 for PostgreSQL with vector support
- Database credentials are in docker-compose.yaml

## Key Implementation Details

**Blog Scraping Strategy:**
- Uses flexible HTML parsing to handle various blog layouts
- Looks for `article`, `.post`, `.blog-post` elements first
- Falls back to scanning `a[href*="/blog/"]` links
- Extracts title, URL, excerpt, publish date, and author
- Returns top 10 most recent posts

**ATOM Feed Compliance:**
- Follows RFC 4287 specification
- Includes proper namespaces, metadata, and entry structure
- Uses RFC 3339 datetime formatting
- Includes caching headers (1 hour cache)
- Supports CORS for cross-origin requests

**Error Handling:**
- Graceful fallback when blog scraping fails
- Detailed error logging via Serverpod's logging system
- Returns HTTP 500 with error message on feed generation failure