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

    return Card(
      color: Colors.white.withOpacity(0.03),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: ListTile(
        leading: const Icon(Icons.vpn_key_outlined, color: Colors.cyanAccent, size: 18),
        title: Text(displayTitle, style: const TextStyle(fontSize: 15)),
        subtitle: Row(
          children: [
            Text(
              data['created_at'] != null 
                ? (data['created_at'] as Timestamp).toDate().toString().substring(5, 16) 
                : '同步中',
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
            if (mediaCount > 0) ...[
              const SizedBox(width: 12),
              const Icon(Icons.attach_file, size: 12, color: Colors.cyanAccent),
              const SizedBox(width: 2),
              Text("$mediaCount 个附件", style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white24, size: 20),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}