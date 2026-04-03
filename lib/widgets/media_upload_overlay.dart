import 'package:flutter/material.dart';

class MediaUploadOverlay extends StatefulWidget {
  final String fileName;
  final int uploadedBytes;
  final int totalBytes;
  final bool isCompleted;

  const MediaUploadOverlay({
    super.key,
    required this.fileName,
    required this.uploadedBytes,
    required this.totalBytes,
    required this.isCompleted,
  });

  @override
  State<MediaUploadOverlay> createState() => _MediaUploadOverlayState();
}

class _MediaUploadOverlayState extends State<MediaUploadOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!widget.isCompleted) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalBytes > 0
        ? widget.uploadedBytes / widget.totalBytes
        : 0.0;

    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 动画加载圆
            ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 进度环
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.cyanAccent,
                        ),
                      ),
                    ),
                    // 中心图标
                    Icon(
                      widget.isCompleted ? Icons.check : Icons.cloud_upload,
                      color: widget.isCompleted
                          ? Colors.greenAccent
                          : Colors.cyanAccent,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 文件名
            Text(
              widget.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 15),

            // 进度信息
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatBytes(widget.uploadedBytes),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
                Text(
                  _formatBytes(widget.totalBytes),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 完成/上传中的状态文本
            Text(
              widget.isCompleted ? 'UPLOAD COMPLETED' : 'UPLOADING...',
              style: TextStyle(
                color: widget.isCompleted
                    ? Colors.greenAccent
                    : Colors.cyanAccent,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.cyanAccent,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 百分比
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
