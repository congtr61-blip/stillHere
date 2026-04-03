import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'detail_screen.dart';
import '../widgets/archive_card.dart';
import '../widgets/media_upload_overlay.dart';
import '../widgets/daily_verification_dialog.dart';
import '../services/media_service.dart';
import '../services/record_verification_service.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;
  
  const DashboardScreen({super.key, required this.uid});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RecordVerificationService _verificationService = RecordVerificationService();
  
  late String _uid;
  String? _userEmail;

  Timer? _timer;
  DateTime? _lastHeartbeat;
  Duration _remainingTime = const Duration(days: 3);
  final Duration _totalCycle = const Duration(days: 3); 

  bool _isSyncing = false;
  
  // 动画控制器
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _uid = widget.uid;
    _userEmail = _auth.currentUser?.email ?? "User";
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _startHeartbeatMonitor();
    _loadUserStatus();
    _performDailyVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStatus() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (doc.exists && doc.data()?['lastHeartbeat'] != null) {
      if (mounted) {
        setState(() {
          _lastHeartbeat = (doc.data()?['lastHeartbeat'] as Timestamp).toDate();
          _updateCountdown();
        });
      }
    }
  }

  void _startHeartbeatMonitor() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lastHeartbeat != null && mounted) {
        setState(() => _updateCountdown());
      }
    });
  }

  Future<void> _performDailyVerification() async {
    try {
      // 检查是否已经校验过今天
      final hasCheckedToday = await _verificationService.hasCheckedToday(_uid);
      
      if (hasCheckedToday) {
        return; // 已校验过，不需要再次显示
      }

      // 执行校验
      final verificationResult = await _verificationService.dailyRecordsCheck(_uid);

      if (mounted) {
        // 标记已完成校验
        await _verificationService.markVerificationComplete(_uid);

        if (verificationResult['needsVerification'] == true ||
            verificationResult['hasPendingRecords'] == true) {
          // 显示校验对话框
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => DailyVerificationDialog(
              verificationResult: verificationResult,
              onDismiss: () {},
            ),
          );
        }
      }
    } catch (e) {
      // 忽略错误，不影响正常使用
      return;
    }
  }

  void _updateCountdown() {
    if (_lastHeartbeat == null) return;
    final nextCheck = _lastHeartbeat!.add(_totalCycle);
    _remainingTime = nextCheck.difference(DateTime.now());
    if (_remainingTime.isNegative) _remainingTime = Duration.zero;
  }

  Future<void> _handleHeartbeat() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    _pulseController.repeat(); 

    try {
      final now = DateTime.now();
      await _firestore.collection('users').doc(_uid).set({
        'lastHeartbeat': now,
        'status': 'active',
        'email': _userEmail,
      }, SetOptions(merge: true));
      
      // 增加仪式感延迟
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        setState(() {
          _lastHeartbeat = now;
          _isSyncing = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        _pulseController.stop();
        _pulseController.reset();
        _showSnackBar("SIGNAL INTERRUPTED: $e");
      }
    }
  }

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('users').doc(_uid).collection('records').doc(docId).delete();
      _showSnackBar("DELETED FROM CLOUD");
    } catch (e) {
      _showSnackBar("DELETE FAILED: $e");
    }
  }

  void _showDeleteConfirm(String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.redAccent, width: 0.3)),
        title: const Text("ERASE DATA", style: TextStyle(color: Colors.redAccent, fontSize: 14, letterSpacing: 2)),
        content: Text("Confirm permanent deletion of [$title]?", style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () { Navigator.pop(context); _deleteRecord(docId); },
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    final titleController = TextEditingController();
    final heirEmailController = TextEditingController();
    final contentController = TextEditingController();
    final mediaService = MediaService();
    
    List<Map<String, dynamic>> uploadedMedia = [];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.cyanAccent, width: 0.2),
          ),
          title: const Text("NEW INSTRUCTION", style: TextStyle(color: Colors.cyanAccent, fontSize: 16, letterSpacing: 2)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, "TITLE"),
                _buildTextField(heirEmailController, "HEIR EMAIL"),
                _buildTextField(contentController, "CONTENT", maxLines: 3),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 15),
                
                // 媒体上传按钮
                const Text(
                  "ATTACH MEDIA",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildMediaButton(
                      context: context,
                      setState: setState,
                      mediaService: mediaService,
                      uploadedMedia: uploadedMedia,
                      isUploading: isUploading,
                      fileType: 'image',
                      label: '📷 IMAGE',
                    ),
                    _buildMediaButton(
                      context: context,
                      setState: setState,
                      mediaService: mediaService,
                      uploadedMedia: uploadedMedia,
                      isUploading: isUploading,
                      fileType: 'video',
                      label: '🎥 VIDEO',
                    ),
                    _buildMediaButton(
                      context: context,
                      setState: setState,
                      mediaService: mediaService,
                      uploadedMedia: uploadedMedia,
                      isUploading: isUploading,
                      fileType: 'audio',
                      label: '🎵 AUDIO',
                    ),
                  ],
                ),
                
                // 显示已上传的媒体
                if (uploadedMedia.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),
                  const Text(
                    "ATTACHED MEDIA",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: uploadedMedia.asMap().entries.map((entry) {
                      int index = entry.key;
                      var media = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MediaService.getMediaIcon(media['type'] as String),
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    media['name'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    MediaService.formatFileSize(media['size'] as int),
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                              onPressed: () {
                                setState(() => uploadedMedia.removeAt(index));
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white24)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: isUploading
                  ? null
                  : () async {
                      // 验证所有必填字段
                      final title = titleController.text.trim();
                      final heirEmail = heirEmailController.text.trim();
                      final content = contentController.text.trim();
                      
                      if (title.isEmpty) {
                        _showSnackBar("✗ TITLE is required");
                        return;
                      }
                      
                      if (heirEmail.isEmpty) {
                        _showSnackBar("✗ HEIR EMAIL is required");
                        return;
                      }
                      
                      if (content.isEmpty) {
                        _showSnackBar("✗ CONTENT is required");
                        return;
                      }
                      
                      // 验证邮箱格式
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(heirEmail)) {
                        _showSnackBar("✗ Invalid EMAIL format");
                        return;
                      }
                      
                      try {
                        // 创建记录
                        await _firestore
                            .collection('users')
                            .doc(_uid)
                            .collection('records')
                            .add({
                          'title': title,
                          'heirEmail': heirEmail,
                          'content': content,
                          'media': uploadedMedia,
                          'createdAt': FieldValue.serverTimestamp(),
                          'status': 'draft',
                        });
                        
                        if (mounted) {
                          Navigator.pop(context);
                          final message = uploadedMedia.isEmpty
                              ? "✓ INSTRUCTION SAVED"
                              : "✓ SAVED WITH ${uploadedMedia.length} FILE(S)";
                          _showSnackBar(message);
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar("✗ SAVE FAILED: $e");
                        }
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required BuildContext context,
    required StateSetter setState,
    required MediaService mediaService,
    required List<Map<String, dynamic>> uploadedMedia,
    required bool isUploading,
    required String fileType,
    required String label,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.cyanAccent,
        side: const BorderSide(color: Colors.cyanAccent, width: 0.5),
      ),
      onPressed: isUploading
          ? null
          : () async {
              try {
                // 先创建临时记录ID用于上传
                final tempRecordId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                
                // 立即显示上传中的 overlay
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => MediaUploadOverlay(
                    fileName: 'Uploading file...',
                    uploadedBytes: 0,
                    totalBytes: 1,
                    isCompleted: false,
                  ),
                );

                setState(() {
                  isUploading = true;
                });
                
                final mediaInfo = await mediaService.uploadMedia(
                  uid: _uid,
                  recordId: tempRecordId,
                  fileType: fileType,
                  onProgress: (uploaded, total) {
                    // 上传进度回调
                  },
                );

                if (mounted) {
                  // 关闭上传中的 dialog
                  Navigator.pop(context);

                  if (mediaInfo != null && !mediaInfo.containsKey('error')) {
                    // 上传成功
                    // 显示上传完成的 overlay
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => MediaUploadOverlay(
                        fileName: mediaInfo['name'] ?? 'Unknown File',
                        uploadedBytes: mediaInfo['size'] ?? 0,
                        totalBytes: mediaInfo['size'] ?? 1,
                        isCompleted: true,
                      ),
                    );

                    // 延迟后关闭 dialog 并更新列表
                    await Future.delayed(const Duration(milliseconds: 1500));
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {
                        uploadedMedia.add(mediaInfo);
                        isUploading = false;
                      });
                      if (mounted) {
                        _showSnackBar("✓ ATTACHED: ${mediaInfo['name']}");
                      }
                    }
                  } else if (mediaInfo != null && mediaInfo.containsKey('error')) {
                    // 上传失败，显示特定的错误信息
                    setState(() {
                      isUploading = false;
                    });
                    final errorMsg = mediaInfo['error'] as String;
                    _showSnackBar("✗ UPLOAD ERROR: $errorMsg");
                  } else {
                    // 用户取消上传
                    setState(() {
                      isUploading = false;
                    });
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    isUploading = false;
                  });
                  _showSnackBar("✗ UPLOAD FAILED: $e");
                }
              }
            },
      icon: const Icon(Icons.add),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFF1C1C1C), content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 12))));
  }

  @override
  Widget build(BuildContext context) {
    double progress = _remainingTime.inSeconds / _totalCycle.inSeconds;
    String days = _remainingTime.inDays.toString();
    String hours = (_remainingTime.inHours % 24).toString().padLeft(2, '0');
    String minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    String timeStr = "$days d  $hours:$minutes:$seconds";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 50),
          // 自定义顶部栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.radar, color: Colors.cyanAccent, size: 18),
                const Text("STILL HERE", style: TextStyle(color: Colors.white, letterSpacing: 8, fontWeight: FontWeight.w100, fontSize: 18)),
                const SizedBox(width: 18),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // --- 固定高度的圆环区域：防止列表抖动 ---
          SizedBox(
            height: 340, 
            child: Center(
              child: GestureDetector(
                onTap: _isSyncing ? null : _handleHeartbeat,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none, // 允许扩散动画溢出而不撑开容器
                  children: [
                    // 动态扩散光圈
                    if (_isSyncing)
                      ...List.generate(3, (i) => AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 250 + (_pulseController.value * 80 * (i + 1)),
                            height: 250 + (_pulseController.value * 80 * (i + 1)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(1 - _pulseController.value),
                                width: 1.0,
                              ),
                            ),
                          );
                        },
                      )),

                    // 静态发光阴影层
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 240, height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(_isSyncing ? 0.4 : 0.05),
                            blurRadius: _isSyncing ? 100 : 40,
                          ),
                        ],
                      ),
                    ),
                    
                    // 进度环
                    SizedBox(
                      width: 250, height: 250,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 1.5,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _remainingTime.inHours < 12 ? Colors.redAccent : Colors.cyanAccent,
                        ),
                      ),
                    ),
                    
                    // 中心信息
                    Container(
                      width: 210, height: 210,
                      decoration: BoxDecoration(
                        color: const Color(0xFF080808),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isSyncing ? "SYNCING..." : "SECURE CONNECTION", style: const TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 2)),
                          const SizedBox(height: 15),
                          Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w100, fontFamily: 'monospace')),
                          const SizedBox(height: 20),
                          Icon(Icons.fingerprint, color: _isSyncing ? Colors.cyanAccent : Colors.white10, size: 35),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // --- 列表区域 ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(_uid).collection('records').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    
                    return ArchiveCard(
                      doc: doc,
                      uid: _uid,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            docId: doc.id,
                            uid: _uid,
                            initialData: doc.data() as Map<String, dynamic>,
                          ),
                        ),
                      ),
                      onDelete: () => _showDeleteConfirm(
                        doc.id,
                        (doc.data() as Map<String, dynamic>)['title'] ?? 'UNKNOWN',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        backgroundColor: Colors.cyanAccent,
        mini: true,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}