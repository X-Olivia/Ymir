import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ImageAnalysisService {
  // Add a simple in-memory cache
  static final Map<String, Map<String, dynamic>> _analysisCache = {};
  
  // General image analysis prompt
  static const String _imageAnalysisPrompt = '''
You are a professional image analyst. Please carefully observe the images uploaded by users and provide a detailed analysis report in the following format:

**Image content description:**
- main object/figure/scene
- action or status description
- Spatial layout and positional relationships
- Detailed description

**Visual element details:**
- Color matching (main color, auxiliary color, color contrast)
- Light conditions (natural light/Artificial light, chiaroscuro, light and shadow effects)
- Material texture (if any obvious features)
- Detailed features (important decorations, logos, text, etc.)

**Composition features:**
- Composition style (centered, rule of thirds, symmetry, etc.)
- Viewing angles and shooting angles
- Depth of field effect
- Image balance

**Emotional atmosphere:**
- overall emotional feeling
- Style characteristics (modern, retro, simple, gorgeous, etc.)
- The artistic conception or theme conveyed

**Technical quality:**
- clarity and focus
- Exposure
- Compositional integrity

Please describe in concise and clear language, focusing on the features and highlights of each image. If there are multiple images, analyze each image individually and summarize the overall visual style and thematic coherence at the end.
''';

  /// Analyze image content
  static Future<Map<String, dynamic>> analyzeImages({
    required List<String> imagePaths,
  }) async {
    try {
      // Validate input
      if (imagePaths.isEmpty) {
        return {
          'success': false,
          'error': 'No image path provided',
        };
      }

      // Filter valid image files
      final validImagePaths = imagePaths.where((path) => isValidImageFile(path)).toList();
      if (validImagePaths.isEmpty) {
        return {
          'success': false,
          'error': 'No valid image files',
        };
      }

      print('📸 Starting analysis of ${validImagePaths.length} images');

      // Check cache
      final cacheKey = _generateCacheKey(validImagePaths);
      final cachedResult = _analysisCache[cacheKey];
      if (cachedResult != null) {
        print('💾 Using cached analysis results');
        return cachedResult;
      }

      Map<String, dynamic> result;
      
      if (validImagePaths.length == 1) {
        // Single image: direct analysis
        print('🔍 Single image analysis');
        result = await _sendAnalysisRequest(validImagePaths);
      } else {
        // Multiple images: analyze separately and then merge
        print('🔍 Analyze multiple images separately');
        result = await _analyzeMultipleImagesSeparately(validImagePaths);
      }

      // Caching results
      if (result['success'] == true) {
        _analysisCache[cacheKey] = result;
        print('💾 Analysis results cached');
        
        // Limit cache size to avoid memory leaks
        if (_analysisCache.length > 10) {
          final firstKey = _analysisCache.keys.first;
          _analysisCache.remove(firstKey);
          print('🗑️ Clean old caches, current cache count: ${_analysisCache.length}');
        }
      }

      return result;
    } catch (e) {
      print('❌ Image analysis error: $e');
      return {
        'success': false,
        'error': 'Image analysis service error: $e',
      };
    }
  }

  /// Analyze multiple images separately and merge the results
  static Future<Map<String, dynamic>> _analyzeMultipleImagesSeparately(List<String> imagePaths) async {
    try {
      List<String> analysisResults = [];
      int totalTokens = 0;
      
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        print('📸 Analyzing image ${i + 1}/${imagePaths.length}');
        
        final result = await _sendAnalysisRequest([imagePath]);
        
        if (result['success'] == true) {
          final analysis = result['analysis'] as String;
          final imageAnalysis = '[Image ${i + 1}]\n$analysis';
          analysisResults.add(imageAnalysis);
          totalTokens += (result['tokensUsed'] as int? ?? 0);
          
          print('✅ Analysis of image ${i + 1} completed');
          
          // Add a delay to avoid sending API requests too frequently
          if (i < imagePaths.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          print('❌ Analysis of image ${i + 1} failed: ${result['error']}');
          analysisResults.add('[Image ${i + 1}]\nAnalysis failed: ${result['error']}');
        }
      }
      
      if (analysisResults.isEmpty) {
        return {
          'success': false,
          'error': 'All image analyses failed',
        };
      }
      
      // Combine analysis results
      final combinedAnalysis = '''
The user uploaded ${imagePaths.length} images. Here is a detailed analysis:

${analysisResults.join('\n\n')}

[Overall summary]
These ${imagePaths.length} images show what the user wants to share. Each has distinct qualities and intent. Use the user's specific needs to select the best image or offer appropriate suggestions.
''';
      
      print('✅ Multiple-image analysis completed, total token usage: $totalTokens');
      
      return {
        'success': true,
        'analysis': combinedAnalysis,
        'tokensUsed': totalTokens,
      };
      
    } catch (e) {
      print('❌ Multiple-image analysis error: $e');
      return {
        'success': false,
        'error': 'Multiple-image analysis error: $e',
      };
    }
  }

  /// Generate cache key
  static String _generateCacheKey(List<String> imagePaths) {
    final pathsString = imagePaths.join('|');
    final bytes = utf8.encode(pathsString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Send an image analysis request to the API
  static Future<Map<String, dynamic>> _sendAnalysisRequest(List<String> imagePaths) async {
    try {
      // Prepare image data
      List<Map<String, dynamic>> imageContents = [];
      
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (!file.existsSync()) {
          print('❌ Image file does not exist: $imagePath');
          continue;
        }

        // Check file size
        final bytes = await file.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);
        
        Uint8List finalImageBytes;
        String processInfo;
        
        if (bytes.length > ApiConfig.maxAnalysisImageSize) {
          print('📸 The image is too large and needs to be compressed...');
          
          // Try compressing the image
          final compressedBytes = await _compressImage(bytes, imagePath);
          if (compressedBytes != null) {
            final compressedSizeMB = compressedBytes.length / (1024 * 1024);
            if (compressedBytes.length <= ApiConfig.maxAnalysisImageSize) {
              finalImageBytes = compressedBytes;
              processInfo = 'Compressed: ${compressedSizeMB.toStringAsFixed(2)} MB';
              print('✅ Compression successful');
            } else {
              print('❌ Still too large after compression, skip processing');
              continue;
            }
          } else {
            print('❌ Image compression failed, skipping processing');
            continue;
          }
        } else {
          finalImageBytes = bytes;
          processInfo = 'Original: ${sizeInMB.toStringAsFixed(2)} MB';
        }
        
        // Convert to base64
        final base64Image = base64Encode(finalImageBytes);
        
        // Get image format
        String format = 'jpeg';
        if (imagePath.toLowerCase().endsWith('.png')) {
          format = 'png';
        } else if (imagePath.toLowerCase().endsWith('.gif')) {
          format = 'gif';
        } else if (imagePath.toLowerCase().endsWith('.webp')) {
          format = 'webp';
        }

        imageContents.add({
          "type": "image_url",
          "image_url": {
            "url": "data:image/$format;base64,$base64Image"
          }
        });
      }

      if (imageContents.isEmpty) {
        return {
          'success': false,
          'error': 'No valid image files were found. The images may be too large; use files smaller than ${ApiConfig.maxAnalysisImageSize ~/ (1024 * 1024)} MB.',
        };
      }

      // Build message content
      List<Map<String, dynamic>> messageContent = [
        {
          "type": "text",
          "text": _imageAnalysisPrompt
        },
        ...imageContents,
      ];

      // Build request body
      final requestBody = {
        "model": ApiConfig.defaultVisionModel,
        "messages": [
          {
            "role": "user",
            "content": messageContent
          }
        ],
        "max_tokens": ApiConfig.visionMaxTokens, // Use the configured vision-model token limit
        "temperature": 0.3, // Lower temperatures for more objective analysis
      };

      // Send request
      print('🚀 Sending image analysis request');
      
      final response = await http.post(
        Uri.parse(ApiConfig.apiUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.requestTimeout); // Add timeout configuration

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          final tokensUsed = data['usage']?['total_tokens'] ?? 0;
          
          print('✅ Image analysis succeeded - token usage: $tokensUsed');
          
          return {
            'success': true,
            'analysis': content,
            'tokensUsed': tokensUsed,
          };
        } else {
          print('❌ Invalid API response format');
          return {
            'success': false,
            'error': 'Invalid API response format',
          };
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        print('❌ API request failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'API request failed: ${response.statusCode} - $errorMessage',
        };
      }
    } catch (e) {
      print('❌ Image analysis request error: $e');
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'error': 'Request timed out, please check network connection',
        };
      } else {
        return {
          'success': false,
          'error': 'Request error: $e',
        };
      }
    }
  }

  /// Get a simplified version of image analysis (for debugging or previewing)
  static String getAnalysisPreview(String fullAnalysis) {
    // Extract the main content and generate a simplified version
    final lines = fullAnalysis.split('\n');
    final preview = <String>[];
    
    for (String line in lines) {
      if (line.trim().isNotEmpty &&
          (line.contains('main') ||
           line.contains('color') ||
           line.contains('composition') ||
           line.contains('emotion') ||
           line.contains('style'))) {
        preview.add(line.trim());
        if (preview.length >= 5) break; // Limit preview length
      }
    }
    
    return preview.join('\n');
  }

  /// Verify that the image file is valid
  static bool isValidImageFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return false;
    
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Get the image file size in MB
  static double getImageSizeMB(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return 0.0;
    
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Intelligent image compression
  /// Dynamically adjust compression quality to keep the result below 5 MB
  static Future<Uint8List?> _compressImage(Uint8List originalBytes, String imagePath) async {
    try {
      // Decode images
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Get original image size
      final int originalWidth = image.width;
      final int originalHeight = image.height;
      final double originalSizeMB = originalBytes.length / (1024 * 1024);
      
      // Calculate a compression ratio that should keep the result below 5 MB
      // More aggressive compression strategies
      double scaleFactor = 1.0;
      
      // Dynamically calculate scaling based on file size (more aggressive)
      if (originalSizeMB > 50) {
        scaleFactor = 0.2; // Extremely large files: scale to 20%
      } else if (originalSizeMB > 30) {
        scaleFactor = 0.25; // Very large files: scale to 25%
      } else if (originalSizeMB > 20) {
        scaleFactor = 0.3; // Large files: scale to 30%
      } else if (originalSizeMB > 15) {
        scaleFactor = 0.35; // Medium-large files: scale to 35%
      } else if (originalSizeMB > 10) {
        scaleFactor = 0.4; // Medium files: scale to 40%
      } else if (originalSizeMB > 7) {
        scaleFactor = 0.5; // Moderately large files: scale to 50%
      } else {
        scaleFactor = 0.6; // Files near the limit: scale to 60%
      }
      
      final int targetWidth = (originalWidth * scaleFactor).round();
      final int targetHeight = (originalHeight * scaleFactor).round();
      
      // Create a canvas and draw the scaled image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // Draw a scaled image
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        ui.Paint(),
      );
      
      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(targetWidth, targetHeight);
      
      // Try different compression methods, giving priority to formats with better compression effects
      Uint8List? bestResult;
      double bestSizeMB = double.infinity;
      
      // tryJPEGformat (generally better compression)
      try {
        // Notice:FlutterofImageByteFormatNoJPEG, we usePNGand then handle it manually
        final ByteData? pngData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
        if (pngData != null) {
          final pngBytes = pngData.buffer.asUint8List();
          final pngSizeMB = pngBytes.length / (1024 * 1024);
          
          if (pngSizeMB < bestSizeMB) {
            bestResult = pngBytes;
            bestSizeMB = pngSizeMB;
          }
        }
      } catch (e) {
        print('PNGCompression failed: $e');
      }
      
      // ifPNGStill too large after compression, try to reduce it further
      if (bestSizeMB > (ApiConfig.maxAnalysisImageSize / (1024 * 1024))) {
        
        // further reduced to half of original size
        final int smallerWidth = (targetWidth * 0.7).round();
        final int smallerHeight = (targetHeight * 0.7).round();
        
        final ui.PictureRecorder smallerRecorder = ui.PictureRecorder();
        final ui.Canvas smallerCanvas = ui.Canvas(smallerRecorder);
        
        smallerCanvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
          ui.Rect.fromLTWH(0, 0, smallerWidth.toDouble(), smallerHeight.toDouble()),
          ui.Paint(),
        );
        
        final ui.Picture smallerPicture = smallerRecorder.endRecording();
        final ui.Image smallerImage = await smallerPicture.toImage(smallerWidth, smallerHeight);
        
        final ByteData? smallerData = await smallerImage.toByteData(format: ui.ImageByteFormat.png);
        if (smallerData != null) {
          final smallerBytes = smallerData.buffer.asUint8List();
          final smallerSizeMB = smallerBytes.length / (1024 * 1024);
          
          if (smallerSizeMB < bestSizeMB) {
            bestResult = smallerBytes;
            bestSizeMB = smallerSizeMB;
          }
        }
        
        smallerImage.dispose();
      }
      
      image.dispose();
      resizedImage.dispose();
      
      if (bestResult != null) {
        return bestResult;
      }
      
      return null;
    } catch (e) {
      print('❌ Image compression error: $e');
      return null;
    }
  }
} 