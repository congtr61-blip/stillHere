import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/crypto_service.dart';

class ArchiveCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String uid;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ArchiveCard({
    super.key,
    required this.doc,
    required this.uid,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String displayTitle = CryptoService.decryptText(data['title'] ?? "", uid);
    final List currentMedia = data['media_data'] as List? ?? [];
    final int mediaCount = currentMedia.length;
    
    // 获取发送状态
    final String sendStatus = data['status'] ?? 'draft';
    final bool isDelivered = sendStatus == 'delivered';
    final bool isFailed = sendStatus == 'failed';
    final bool isDraft = sendStatus == 'draft' || !data.containsKey('status');

    return Card(
      color: Colors.white.withOpacity(0.03),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: ListTile(
        leading: Icon(
          isDelivered ? Icons.check_circle : (isFailed ? Icons.error_outline : Icons.vpn_key_outlined),
          color: isDelivered ? Colors.greenAccent : (isFailed ? Colors.redAccent : Colors.cyanAccent),
          size: 18,
        ),
        title: Text(displayTitle, style: const TextStyle(fontSize: 15)),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data['createdAt'] != null 
                          ? (data['createdAt'] as Timestamp).toDate().toString().substring(5, 16) 
                          : '同步中',
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                      if (isDelivered && data['sentAt'] != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.send, size: 10, color: Colors.greenAccent),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(data['sentAt'] as Timestamp),
                          style: const TextStyle(fontSize: 9, color: Colors.greenAccent),
                        ),
                      ],
                      if (isFailed) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.close, size: 10, color: Colors.redAccent),
                        const SizedBox(width: 3),
                        const Text(
                          '发送失败',
                          style: TextStyle(fontSize: 9, color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                  if (mediaCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_file, size: 10, color: Colors.cyanAccent),
                        const SizedBox(width: 2),
                        Text("$mediaCount 个附件", style: const TextStyle(fontSize: 9, color: Colors.cyanAccent)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDelivered)
              const Tooltip(
                message: '已分发',
                child: Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 16),
              ),
            if (isDraft)
              const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white24, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}