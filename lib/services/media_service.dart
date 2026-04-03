import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

typedef UploadProgressCallback = Function(int uploadedBytes, int totalBytes);

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 上传单个媒体文件到 Firebase Storage
  /// [uid] 用户ID
  /// [recordId] 记录ID
  /// [fileType] 文件类型: 'image', 'video', 'audio'
  /// [onProgress] 上传进度回调
  /// 返回上传后的媒体信息 Map 或错误信息 {'error': '错误详情'}
  Future<Map<String, dynamic>?> uploadMedia({
    required String uid,
    required String recordId,
    required String fileType,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // 文件类型选择器
      FileType pickerFileType;
      List<String>? allowedExtensions;

      switch (fileType) {
        case 'image':
          pickerFileType = FileType.image;
          allowedExtensions = null;
          break;
        case 'video':
          pickerFileType = FileType.video;
          allowedExtensions = null;
          break;
        case 'audio':
          pickerFileType = FileType.audio;
          allowedExtensions = null;
          break;
        default:
          pickerFileType = FileType.any;
      }

      // 打开文件选择器
      final result = await FilePicker.platform.pickFiles(
        type: pickerFileType,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return null; // 用户取消选择
      }

      // 获取文件数据
      final fileName = result.files.single.name;
      final fileBytes = result.files.single.bytes;

      if (fileBytes == null) {
        return {'error': 'Failed to read file data'};
      }

      final fileSize = fileBytes.length;

      // 检查文件大小（限制 100MB）
      if (fileSize > 100 * 1024 * 1024) {
        return {'error': 'File size exceeds 100MB limit. Size: ${formatFileSize(fileSize)}'};
      }

      // 生成简短的存储文件名（使用类型 + 时间戳 + 扩展名）
      final ext = fileName.lastIndexOf('.') > 0 
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '';
      final shortFileName = '${fileType}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}$ext';
      
      // 生成储存路径
      final storagePath = 'users/$uid/records/$recordId/media/$shortFileName';

      developer.log('Starting upload: $fileName ($fileType, ${formatFileSize(fileSize)}) to $storagePath', name: 'MediaService');

      // 创建存储引用
      final ref = _storage.ref(storagePath);

      // 上传到 Firebase Storage，支持进度回调
      // 使用 putData 支持 web 平台
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );
      
      // 监听上传进度
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        developer.log('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}', name: 'MediaService');
        if (onProgress != null) {
          onProgress(snapshot.bytesTransferred, snapshot.totalBytes);
        }
      });

      // 等待上传完成
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      developer.log('Upload complete: $downloadUrl', name: 'MediaService');

      // 生成简洁的显示名称
      String displayName = fileName;
      if (fileName.length > 30) {
        final ext = fileName.lastIndexOf('.') > 0 
            ? fileName.substring(fileName.lastIndexOf('.'))
            : '';
        displayName = '${fileName.substring(0, 15)}...${ext.isNotEmpty ? ext : ''}';
      }

      // 返回媒体信息
      final mediaInfo = {
        'url': downloadUrl,
        'type': fileType, // 'image', 'video', 'audio'
        'name': displayName, // 显示用的简洁名称
        'originalName': fileName, // 保存原始名称
        'size': fileSize,
        'uploadedAt': DateTime.now().toIso8601String(),
        'storagePath': storagePath,
      };

      return mediaInfo;
    } on FirebaseException catch (e) {
      String errorMsg = 'Upload failed: ${e.code}';
      
      // 输出详细错误日志
      developer.log('FirebaseException during upload: Code="${e.code}", Message="${e.message}"', name: 'MediaService');
      
      // 更详细的错误信息
      switch (e.code) {
        case 'permission-denied':
          errorMsg = 'Permission denied. Check Firebase Storage rules.';
          break;
        case 'unauthenticated':
          errorMsg = 'Please sign in to upload files.';
          break;
        case 'invalid-argument':
          errorMsg = 'Invalid file or path.';
          break;
        case 'storage-error':
          errorMsg = 'Storage service error: ${e.message}';
          break;
        default:
          errorMsg = 'Firebase error: ${e.message ?? e.code}';
      }
      
      return {'error': errorMsg};
    } catch (e) {
      developer.log('Unexpected error during upload: ${e.toString()}', name: 'MediaService');
      return {'error': 'Unexpected error: ${e.toString()}'};
    }
  }

  /// 删除媒体文件
  Future<void> deleteMedia({
    required String storagePath,
    required String uid,
    required String recordId,
    required String mediaIndex,
  }) async {
    try {
      // 从 Storage 删除文件
      await _storage.ref(storagePath).delete();

      // 从 Firestore 删除媒体记录
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('records')
          .doc(recordId)
          .update({
        'media': FieldValue.arrayRemove([
          {'storagePath': storagePath}
        ])
      });
    } catch (e) {
      return;
    }
  }

  /// 获取文件的 MIME 类型
  static String _getContentType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      default:
        return 'application/octet-stream';
    }
  }

  /// 获取文件大小的可读格式
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 获取媒体类型的图标
  static IconData getMediaIcon(String mediaType) {
    switch (mediaType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audio_file;
      default:
        return Icons.attachment;
    }
  }
}
