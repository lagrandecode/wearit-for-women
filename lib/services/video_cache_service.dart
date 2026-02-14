import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for videos with longer cache duration
class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._internal();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();

  static const String _cacheKey = 'videoCache';
  
  // Cache manager with 30 days expiry for videos
  static final CacheManager _cacheManager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50, // Limit to 50 cached videos
      repo: JsonCacheInfoRepository(databaseName: _cacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Get cached video file, or download and cache if not exists
  Future<File> getCachedVideoFile(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      // If cache fails, throw error to handle in calling code
      rethrow;
    }
  }

  /// Get cached video file path, or download and cache if not exists
  /// Returns file path if cached, or original URL if caching fails
  Future<String> getCachedVideoPath(String url) async {
    try {
      final file = await getCachedVideoFile(url);
      return file.path;
    } catch (e) {
      // Return original URL as fallback if caching fails
      return url;
    }
  }

  /// Check if video is cached
  Future<bool> isCached(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached videos
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Remove specific video from cache
  Future<void> removeFromCache(String url) async {
    await _cacheManager.removeFile(url);
  }

  /// Get cache size (approximate)
  Future<int> getCacheSize() async {
    // Note: flutter_cache_manager doesn't provide direct cache size
    // This would require iterating through cache directory
    return 0; // Placeholder - can be implemented if needed
  }
}
