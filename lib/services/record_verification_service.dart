import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class RecordVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 每日校验记录状态
  /// 检查用户是否有待审核的记录、未发送的记录等
  Future<Map<String, dynamic>> dailyRecordsCheck(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return {'needsVerification': false};
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final lastHeartbeat = userData['lastHeartbeat'] as Timestamp?;
      
      if (lastHeartbeat == null) {
        return {'needsVerification': true, 'reason': 'no_heartbeat'};
      }

      // 计算距离上次心跳的时间
      final now = DateTime.now();
      final lastBeatTime = lastHeartbeat.toDate();
      final difference = now.difference(lastBeatTime);
      
      // 如果距离上次心跳超过 1.5 天，提示需要校验
      if (difference.inHours > 36) {
        return {
          'needsVerification': true,
          'reason': 'heartbeat_expired',
          'lastHeartbeat': lastBeatTime.toString().substring(0, 19),
          'hoursSinceHeartbeat': difference.inHours,
        };
      }

      // 检查是否有失败的记录
      final recordsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('records')
          .where('status', isEqualTo: 'failed')
          .get();

      if (recordsSnapshot.docs.isNotEmpty) {
        return {
          'needsVerification': true,
          'reason': 'failed_records',
          'failedCount': recordsSnapshot.docs.length,
        };
      }

      // 检查是否有未发送的记录（已触发但未发送）
      final unsentSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('records')
          .where('sentAt', isNull: true)
          .where('failedAt', isNull: true)
          .get();

      if (unsentSnapshot.docs.isNotEmpty) {
        return {
          'needsVerification': false,
          'hasPendingRecords': true,
          'pendingCount': unsentSnapshot.docs.length,
        };
      }

      return {'needsVerification': false};
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  /// 获取今天是否已经校验过
  Future<bool> hasCheckedToday(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final lastVerificationTime = userData['lastDailyVerification'] as Timestamp?;

      if (lastVerificationTime == null) {
        return false;
      }

      final now = DateTime.now();
      final lastCheck = lastVerificationTime.toDate();
      
      // 如果距离上次校验不足 23 小时，则认为已校验过
      return now.difference(lastCheck).inHours < 23;
    } catch (e) {
      return false;
    }
  }

  /// 标记已完成今日校验
  Future<void> markVerificationComplete(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'lastDailyVerification': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      return;
    }
  }

  /// 获取心跳倒计时信息
  Future<Map<String, dynamic>> getHeartbeatCountdown(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return {'hasHeartbeat': false};
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final lastHeartbeat = userData['lastHeartbeat'] as Timestamp?;

      if (lastHeartbeat == null) {
        return {'hasHeartbeat': false};
      }

      final now = DateTime.now();
      final lastBeatTime = lastHeartbeat.toDate();
      
      // 3 天的心跳周期
      final threeDays = const Duration(days: 3);
      final nextCheck = lastBeatTime.add(threeDays);
      
      if (now.isAfter(nextCheck)) {
        // 已过期
        return {
          'hasHeartbeat': true,
          'isExpired': true,
          'lastHeartbeat': lastBeatTime.toString().substring(0, 19),
        };
      } else {
        // 未过期
        final remaining = nextCheck.difference(now);
        return {
          'hasHeartbeat': true,
          'isExpired': false,
          'lastHeartbeat': lastBeatTime.toString().substring(0, 19),
          'remainingDays': remaining.inDays,
          'remainingHours': remaining.inHours % 24,
          'remainingMinutes': remaining.inMinutes % 60,
          'remainingSeconds': remaining.inSeconds % 60,
        };
      }
    } catch (e) {
      return {'error': true};
    }
  }
}
