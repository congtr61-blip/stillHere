import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 调试配置
  final String _debugUid = "0k99IZlCNVMM4bttirYKedEHAln1";
  final String _debugEmail = "congtr61@gmail.com";

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _startHeartbeatMonitor();
    _loadUserStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStatus() async {
    final doc = await _firestore.collection('users').doc(_debugUid).get();
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
      await _firestore.collection('users').doc(_debugUid).set({
        'lastHeartbeat': now,
        'status': 'active',
        'email': _debugEmail,
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
      await _firestore.collection('users').doc(_debugUid).collection('records').doc(docId).delete();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.2)),
        title: const Text("NEW INSTRUCTION", style: TextStyle(color: Colors.cyanAccent, fontSize: 16, letterSpacing: 2)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, "TITLE"),
              _buildTextField(heirEmailController, "HEIR EMAIL"),
              _buildTextField(contentController, "CONTENT", maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await _firestore.collection('users').doc(_debugUid).collection('records').add({
                  'title': titleController.text,
                  'heirEmail': heirEmailController.text,
                  'content': contentController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("SAVE"),
          ),
        ],
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
              stream: _firestore.collection('users').doc(_debugUid).collection('records').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    String title = data['title'] ?? 'UNKNOWN';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.cyanAccent.withOpacity(0.3), width: 2))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 20, right: 10, top: 5, bottom: 5),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1)),
                        subtitle: Text("HEIR: ${data['heirEmail']}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        trailing: SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _showDeleteConfirm(docId, title),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.keyboard_arrow_right, color: Colors.white10, size: 18),
                            ],
                          ),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(docId: docId, initialData: data))),
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