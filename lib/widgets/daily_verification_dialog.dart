import 'package:flutter/material.dart';

class DailyVerificationDialog extends StatelessWidget {
  final Map<String, dynamic> verificationResult;
  final VoidCallback onDismiss;

  const DailyVerificationDialog({
    super.key,
    required this.verificationResult,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final String reason = verificationResult['reason'] ?? 'unknown';
    final bool needsVerification = verificationResult['needsVerification'] ?? false;

    // 分析原因，确定要显示的内容和样式
    if (needsVerification && reason == 'heartbeat_expired') {
      return _buildHeartbeatExpiredDialog(context);
    } else if (needsVerification && reason == 'failed_records') {
      return _buildFailedRecordsDialog(context);
    } else if (reason == 'no_heartbeat') {
      return _buildNoHeartbeatDialog(context);
    } else if (verificationResult['hasPendingRecords'] == true) {
      return _buildPendingRecordsDialog(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeartbeatExpiredDialog(BuildContext context) {
    final String lastHeartbeat = verificationResult['lastHeartbeat'] ?? '未知';
    final int hoursSince = verificationResult['hoursSinceHeartbeat'] ?? 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.redAccent, width: 0.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Text(
            'HEARTBEAT CHECK',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '系统检测到您已有较长时间未验证存活状态',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⏱️ 时间信息',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '上次心跳：$lastHeartbeat',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '距今已：$hoursSince 小时',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '请立即点击"验证存活"以重置计时器，以确保您的数字遗产系统继续正常运作。',
            style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('稍后再验', style: TextStyle(color: Colors.white24)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          onPressed: () {
            Navigator.pop(context);
            onDismiss();
          },
          child: const Text('现在验证', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildFailedRecordsDialog(BuildContext context) {
    final int failedCount = verificationResult['failedCount'] ?? 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.orangeAccent, width: 0.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.orangeAccent, size: 24),
          SizedBox(width: 10),
          Text(
            'FAILED RECORDS',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '检测到 $failedCount 条记录分发失败',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '这些记录可能因网络问题或邮件配置问题而未能成功发送。请检查您的邮件配置并重新尝试。',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDismiss();
          },
          child: const Text('我知道了', style: TextStyle(color: Colors.white24)),
        ),
      ],
    );
  }

  Widget _buildNoHeartbeatDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.cyanAccent, width: 0.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.cyanAccent, size: 24),
          SizedBox(width: 10),
          Text(
            'FIRST HEARTBEAT',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '欢迎来到 StillHere！',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '系统检测到这是您的第一次心跳。请点击"验证存活"按钮来建立您的第一个心跳记录。',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 心跳是确保您数字遗产安全性的关键。系统会定期检查您的心跳状态。如果您失联超过 72 小时，系统将自动向继承人发送您设置的遗产指令。',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
            onDismiss();
          },
          child: const Text('现在验证'),
        ),
      ],
    );
  }

  Widget _buildPendingRecordsDialog(BuildContext context) {
    final int pendingCount = verificationResult['pendingCount'] ?? 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.blueAccent, width: 0.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.history, color: Colors.blueAccent, size: 24),
          SizedBox(width: 10),
          Text(
            'PENDING RECORDS',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '您有 $pendingCount 条待分发的记录',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text(
            '这些记录将在系统检测到您失联 72 小时后自动分发给继承人。',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDismiss();
          },
          child: const Text('确定', style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }
}
