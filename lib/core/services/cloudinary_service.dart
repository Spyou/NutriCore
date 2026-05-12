import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

import '../config/env_config.dart';

/// Thin wrapper around `cloudinary_public` for unsigned image uploads.
/// No server-side signing needed — relies on an unsigned upload preset
/// configured in the Cloudinary console.
class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  CloudinaryPublic? _client;

  CloudinaryPublic? get _ensureClient {
    if (!EnvConfig.hasCloudinary) return null;
    _client ??= CloudinaryPublic(
      EnvConfig.cloudinaryCloudName,
      EnvConfig.cloudinaryUploadPreset,
      cache: false,
    );
    return _client;
  }

  bool get isConfigured => EnvConfig.hasCloudinary;

  /// Uploads [file] to Cloudinary. Returns the secure HTTPS URL of the
  /// uploaded image, or null on failure / when Cloudinary isn't configured.
  ///
  /// [folder] is a logical bucket inside your Cloudinary account
  /// (e.g. `profile_images`, `meal_photos`). [publicId] is optional but
  /// recommended for predictable filenames.
  Future<String?> uploadImage(
    File file, {
    required String folder,
    String? publicId,
  }) async {
    final client = _ensureClient;
    if (client == null) {
      if (kDebugMode) {
        print('Cloudinary not configured — skipping upload.');
      }
      return null;
    }
    try {
      final response = await client.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          publicId: publicId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Cloudinary upload failed: $e');
      }
      return null;
    }
  }
}
