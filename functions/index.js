const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp } = require("firebase-admin/firestore");
const nodemailer = require("nodemailer");

admin.initializeApp();

// 邮件发送通道
const transporter = nodemailer.createTransport({
    service: 'Gmail',
    auth: {
        user: process.env.GMAIL_USER, 
        pass: process.env.GMAIL_PASS 
    }
});

// 每天凌晨 00:00 准时扫描 (你可以根据需要修改 cron 表达式)
exports.dailySecurityCheck = onSchedule("0 0 * * *", async (event) => {
    logger.log("--- 启动每日安全扫描与遗产分发程序 ---");
    
    try {
        const db = admin.firestore();
        const now = Timestamp.now();
        
        // 设定 3 天为失联标准 (3 * 24 * 60 * 60 * 1000)
        const THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000;
        const cutoff = Timestamp.fromMillis(now.toMillis() - THREE_DAYS_MS);

        // 1. 寻找状态为 active 且心跳超过 3 天的用户
        const expiredUsers = await db.collection("users")
            .where("status", "==", "active")
            .where("lastHeartbeat", "<", cutoff)
            .get();

        if (expiredUsers.empty) {
            logger.log("扫描完成：未发现失联用户。");
            return null;
        }

        for (const userDoc of expiredUsers.docs) {
            const userData = userDoc.data();
            const uid = userDoc.id;

            logger.log(`检测到失联用户: ${userData.email || uid}，准备执行预设指令...`);

            // 2. 抓取该用户的所有 records 指令
            const recordsSnapshot = await db.collection("users").doc(uid).collection("records").get();

            if (!recordsSnapshot.empty) {
                for (const recordDoc of recordsSnapshot.docs) {
                    const record = recordDoc.data();
                    
                    if (!record.heirEmail || !record.content) continue;

                    const mailOptions = {
                        from: '"StillHere System" <${process.env.GMAIL_USER}>',
                        to: record.heirEmail,
                        subject: `[紧急执行] 来自 ${userData.email || '用户'} 的数字遗产指令: ${record.title}`,
                        text: `这是一封自动触发的邮件。\n\n由于系统检测到 ${userData.email} 的身份确认信号中断已超过 72 小时，现分发其预设内容：\n\n【标题】：${record.title}\n\n【指令内容】：\n${record.content}\n\n---\n本指令由 StillHere 系统根据用户生前设置自动分发。`
                    };

                    try {
                        await transporter.sendMail(mailOptions);
                        logger.log(`[发送成功] -> ${record.heirEmail}`);
                    } catch (mailErr) {
                        logger.error(`[发送失败] 用户 ${uid} 的指令 "${record.title}": ${mailErr.message}`);
                    }
                }
            }

            // 3. 标记为已触发，防止重复发送
            await userDoc.ref.update({ 
                status: "triggered", 
                trigger_time: now 
            });
            logger.log(`用户 ${uid} 状态已更新为 triggered，流程结束。`);
        }
    } catch (error) {
        logger.error("!!! 严重错误:", error.stack);
    }
});