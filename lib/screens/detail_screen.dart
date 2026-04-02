import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _uid = widget.uid;
    _titleController = TextEditingController(text: widget.initialData['title']);
    _emailController = TextEditingController(text: widget.initialData['heirEmail']);
    _contentController = TextEditingController(text: widget.initialData['content']);
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
              
              if (_isEditing) ...[
                const SizedBox(height: 40),
                const Text(
                  "ATTENTION: You are modifying secured data. Changes will be synchronized to the cloud immediately.",
                  style: TextStyle(
                    color: Colors.white12, 
                    fontSize: 10, 
                    fontStyle: FontStyle.italic // 这里修正了错误
                  ),
                ),
              ]
            ],
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