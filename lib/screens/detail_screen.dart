import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/media_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:developer' as developer;

class DetailScreen extends StatefulWidget {
  final String docId;
  final String uid;
  final Map<String, dynamic> initialData;

  const DetailScreen({super.key, required this.docId, required this.uid, required this.initialData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _uid;

  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _contentController;
  late List<Map<String, dynamic>> _mediaList;
  bool _isEditing = false;
  bool _isSaving = false;
  late MediaService _mediaService;

  @override
  void initState() {
    super.initState();
    _uid = widget.uid;
    _mediaService = MediaService();
    _titleController = TextEditingController(text: widget.initialData['title']);
    _emailController = TextEditingController(text: widget.initialData['heirEmail']);
    _contentController = TextEditingController(text: widget.initialData['content']);
    _mediaList = List<Map<String, dynamic>>.from(widget.initialData['media'] ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateData() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('records')
          .doc(widget.docId)
          .update({
        'title': _titleController.text,
        'heirEmail': _emailController.text,
        'content': _contentController.text,
        'media': _mediaList,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ENCRYPTED DATA UPDATED", style: TextStyle(color: Colors.cyanAccent)),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("UPDATE FAILED: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("DATA TERMINAL", style: TextStyle(letterSpacing: 3, fontSize: 14)),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
              ),
            )
          else
            IconButton(
              icon: Icon(_isEditing ? Icons.check_circle : Icons.edit_note, 
                         color: _isEditing ? Colors.greenAccent : Colors.cyanAccent),
              onPressed: () {
                if (_isEditing) {
                  _updateData();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示发送状态信息
              _buildStatusBanner(),
              const SizedBox(height: 25),
              
              _buildTechField("IDENTIFIER / 标题", _titleController, _isEditing),
              const SizedBox(height: 30),
              _buildTechField("RECIPIENT / 继承人邮箱", _emailController, _isEditing),
              const SizedBox(height: 30),
              _buildTechField("ENCRYPTED CONTENT / 加密指令", _contentController, _isEditing, maxLines: 8),
              
              // 媒体文件展示区
              if (_mediaList.isNotEmpty) ...[
                const SizedBox(height: 40),
                const Text(
                  "ATTACHED MEDIA / 附件媒体",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 15),
                ..._buildMediaList(),
              ],
              
              if (_isEditing) ...[
                const SizedBox(height: 40),
                const Text(
                  "ATTENTION: You are modifying secured data. Changes will be synchronized to the cloud immediately.",
                  style: TextStyle(
                    color: Colors.white12, 
                    fontSize: 10, 
                    fontStyle: FontStyle.italic
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMediaList() {
    return _mediaList.asMap().entries.map((entry) {
      int index = entry.key;
      var media = entry.value;
      
      final String mediaType = media['type'] ?? 'unknown';
      final String fileName = media['name'] ?? 'Unknown';
      final int fileSize = media['size'] ?? 0;
      final String url = media['url'] ?? '';
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  MediaService.getMediaIcon(mediaType),
                  color: Colors.cyanAccent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mediaType.toUpperCase()} • ${MediaService.formatFileSize(fileSize)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      setState(() => _mediaList.removeAt(index));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (mediaType == 'image' && url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () => _showImagePreview(context, url, fileName),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: FutureBuilder<Uint8List?>(
                      future: _loadImageBytes(url),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.05),
                            child: Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }
                        
                        // 加载失败
                        return Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.redAccent.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, color: Colors.white54, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onPressed: () => _launchUrl(url),
                                icon: const Icon(Icons.open_in_browser, size: 14),
                                label: const Text('Open', style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (mediaType == 'video' && url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                          foregroundColor: Colors.cyanAccent,
                        ),
                        onPressed: () => _launchUrl(url),
                        icon: const Icon(Icons.play_circle_outline, size: 16),
                        label: const Text('WATCH VIDEO', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                      ),
                      onPressed: () => _launchUrl(url),
                      icon: const Icon(Icons.download_outlined, size: 16, color: Colors.cyanAccent),
                      tooltip: 'Download',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            if (mediaType == 'audio' && url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                          foregroundColor: Colors.cyanAccent,
                        ),
                        onPressed: () => _launchUrl(url),
                        icon: const Icon(Icons.play_circle_outline, size: 16),
                        label: const Text('LISTEN AUDIO', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                      ),
                      onPressed: () => _launchUrl(url),
                      icon: const Icon(Icons.download_outlined, size: 16, color: Colors.cyanAccent),
                      tooltip: 'Download',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  /// 通过 Firebase Storage SDK 加载图片字节数据
  Future<Uint8List?> _loadImageBytes(String url) async {
    try {
      // 提取存储路径和令牌
      // 格式: https://firebasestorage.googleapis.com/v0/b/bucket/o/path?token=xxx
      final uri = Uri.parse(url);
      
      // 从 URL 获取存储路径
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4) {
        return null;
      }
      
      // 提取路径在 /o/ 之后
      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex + 1 >= pathSegments.length) {
        return null;
      }
      
      // 重新构建路径
      final pathParts = pathSegments.sublist(oIndex + 1).join('/');
      final storagePath = Uri.decodeComponent(pathParts);
      
      developer.log('Loading image from Storage path: $storagePath');
      
      // 使用 Firebase Storage SDK 获取字节
      final bytes = await FirebaseStorage.instance
          .ref(storagePath)
          .getData()
          .timeout(const Duration(seconds: 30));
      
      developer.log('Successfully loaded ${bytes!.length} bytes');
      return bytes;
    } catch (e) {
      developer.log('Error loading image from Storage: $e');
      
      // 如果 Storage SDK 失败,尝试通过代理或直接 HTTP
      try {
        final encodedUrl = Uri.encodeComponent(url);
        final proxyUrl = 'https://us-central1-stillhere-ad395.cloudfunctions.net/proxyImage?url=$encodedUrl';
        
        developer.log('Attempting proxy request to: $proxyUrl');
        
        final response = await http.get(Uri.parse(proxyUrl))
            .timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          developer.log('Successfully loaded image through proxy: ${response.bodyBytes.length} bytes');
          return response.bodyBytes;
        }
      } catch (proxyError) {
        developer.log('Proxy error: $proxyError');
      }
      
      return null;
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FutureBuilder<Uint8List?>(
                    future: _loadImageBytes(imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                            ),
                          ),
                        );
                      }
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                        );
                      }
                      
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                            const SizedBox(height: 16),
                            const Text('Failed to load image', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _launchUrl(imageUrl);
                              },
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Open External'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                                  foregroundColor: Colors.cyanAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _launchUrl(imageUrl),
                                icon: const Icon(Icons.download_outlined, size: 14),
                                label: const Text('DOWNLOAD', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('CLOSE', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = widget.initialData['status'] ?? 'draft';
    final isDelivered = status == 'delivered';
    final isFailed = status == 'failed';
    final sentAt = widget.initialData['sentAt'] as Timestamp?;
    final failureReason = widget.initialData['failureReason'] as String?;
    
    if (status == 'draft' || !widget.initialData.containsKey('status')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '草稿状态 - 该指令将在触发时自动分发给继承人',
                style: TextStyle(color: Colors.blue, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    
    if (isDelivered) {
      final dateStr = sentAt != null 
        ? sentAt.toDate().toString().substring(0, 19)
        : '未知';
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.1),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✓ 已分发给继承人',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '分发时间: $dateStr',
              style: TextStyle(color: Colors.greenAccent.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      );
    }
    
    if (isFailed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✗ 分发失败',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (failureReason != null) ...[
              const SizedBox(height: 6),
              Text(
                '原因: $failureReason',
                style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildTechField(String label, TextEditingController controller, bool enabled, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white60, 
            fontSize: 16, 
            fontFamily: 'monospace',
            letterSpacing: 0.5
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white.withOpacity(0.03) : Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent, width: 0.5)),
            disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
        ),
      ],
    );
  }
}