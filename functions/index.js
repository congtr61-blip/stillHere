const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp } = require("firebase-admin/firestore");
const nodemailer = require("nodemailer");
const crypto = require("crypto");
const cors = require("cors");

admin.initializeApp();

// 邮件发送通道
const transporter = nodemailer.createTransport({
    service: 'Gmail',
    auth: {
        user: process.env.GMAIL_USER, 
        pass: process.env.GMAIL_PASS 
    }
});

// 工具函数：格式化文件大小
const formatFileSize = (bytes) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
};

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

                    // 生成验证码和签名
                    const verificationCode = crypto.randomBytes(6).toString('hex').toUpperCase();
                    const signatureData = `${uid}:${recordDoc.id}:${verificationCode}`;
                    const messageSignature = crypto
                        .createHmac('sha256', process.env.SIGNING_SECRET || 'stillhere-secret')
                        .update(signatureData)
                        .digest('hex')
                        .substring(0, 32);
                    
                    const triggerTime = new Date(now.toMillis()).toLocaleString('zh-CN', {
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                        timeZone: 'Asia/Shanghai'
                    });

                    // 生成 HTML 邮件模板
                    const htmlContent = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f0f0f; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: #1a1a1a; border: 1px solid #333; border-radius: 10px; overflow: hidden; }
        .header { background: linear-gradient(135deg, #00bcd4 0%, #0097a7 100%); padding: 30px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 300; letter-spacing: 3px; }
        .header p { margin: 10px 0 0; opacity: 0.8; font-size: 12px; }
        .content { padding: 30px; color: #e0e0e0; }
        .alert { background: #263238; border-left: 4px solid #ff9800; padding: 15px; margin-bottom: 25px; border-radius: 4px; }
        .alert-title { color: #ffb74d; font-weight: bold; margin: 0 0 8px; font-size: 14px; }
        .alert p { margin: 0; font-size: 13px; line-height: 1.6; }
        .info-block { background: #263238; padding: 15px; margin: 20px 0; border-radius: 4px; border: 1px solid #37474f; }
        .info-label { color: #80deea; font-size: 11px; font-weight: bold; letter-spacing: 1px; margin-bottom: 8px; }
        .info-value { color: #e0e0e0; font-size: 13px; word-break: break-all; font-family: 'Courier New', monospace; }
        .instruction-box { background: #1e1e1e; border: 1px solid #0097a7; padding: 20px; margin: 20px 0; border-radius: 4px; }
        .instruction-title { color: #00bcd4; font-size: 14px; font-weight: bold; margin-bottom: 12px; }
        .instruction-content { color: #b0bec5; line-height: 1.8; font-size: 13px; white-space: pre-wrap; word-wrap: break-word; }
        .media-section { background: #1e1e1e; border: 1px solid #00bcd4; padding: 20px; margin: 20px 0; border-radius: 4px; }
        .media-title { color: #00bcd4; font-size: 14px; font-weight: bold; margin-bottom: 15px; }
        .media-item { background: #263238; padding: 12px; margin-bottom: 10px; border-radius: 4px; border-left: 3px solid #00bcd4; }
        .media-item-type { color: #80deea; font-size: 11px; font-weight: bold; letter-spacing: 1px; }
        .media-item-name { color: #e0e0e0; font-size: 13px; margin: 5px 0; word-break: break-all; }
        .media-item-link { display: inline-block; margin-top: 8px; padding: 8px 12px; background: #00bcd4; color: #000; text-decoration: none; border-radius: 3px; font-size: 11px; font-weight: bold; }
        .verification { background: #1e1e1e; padding: 15px; border-radius: 4px; margin: 20px 0; border: 1px dashed #0097a7; text-align: center; }
        .verification-code { font-size: 24px; font-weight: bold; color: #00bcd4; font-family: 'Courier New', monospace; letter-spacing: 2px; margin: 10px 0; }
        .footer { background: #0f0f0f; padding: 20px; text-align: center; border-top: 1px solid #333; font-size: 11px; color: #666; }
        .footer a { color: #00bcd4; text-decoration: none; }
        .security-tips { background: #1a237a; border-left: 4px solid #3f51b5; padding: 12px; margin: 15px 0; border-radius: 3px; font-size: 12px; line-height: 1.6; color: #90caf9; }
        .timestamp { color: #90a4ae; font-size: 11px; margin-top: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>STILL HERE</h1>
            <p>数字遗产自动分发系统</p>
        </div>
        
        <div class="content">
            <div class="alert">
                <div class="alert-title">⚠️ 系统触发通知</div>
                <p>尊敬的继承人，我们的系统检测到一名用户已失联超过 72 小时，现根据其 生前设置自动分发以下预设指令内容。</p>
            </div>

            <div class="info-block">
                <div class="info-label">📧 发件人邮箱</div>
                <div class="info-value">${userData.email || '用户'}</div>
                <div class="timestamp">触发时间: ${triggerTime}</div>
            </div>

            <div class="instruction-box">
                <div class="instruction-title">【${record.title}】</div>
                <div class="instruction-content">${(record.content || '').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</div>
            </div>

            ${
              record.media && record.media.length > 0
                ? `
            <div class="media-section">
                <div class="media-title">📎 附件媒体文件</div>
                ${record.media
                  .map((media) => {
                    const mediaType =
                      media.type === "image"
                        ? "📷 图片"
                        : media.type === "video"
                          ? "🎥 视频"
                          : "🎵 音频";
                    return `
                <div class="media-item">
                    <div class="media-item-type">${mediaType} • ${media.name}</div>
                    <div class="media-item-name">大小: ${formatFileSize(media.size)}</div>
                    <a href="${media.url}" class="media-item-link">查看文件</a>
                </div>
                `;
                  })
                  .join("")}
            </div>
                `
                : ""
            }

            <div class="verification">
                <div style="color: #b0bec5; font-size: 12px; margin-bottom: 8px;">安全验证码</div>
                <div class="verification-code">${verificationCode}</div>
                <div style="color: #64b5f6; font-size: 11px; margin-top: 8px;">
                    收到此邮件后，请保存并妥善保管上述验证码<br/>
                    使用: <code style="background: #263238; padding: 2px 6px; border-radius: 3px;">${messageSignature}</code>
                </div>
            </div>

            <div class="security-tips">
                <strong>🔒 安全提示：</strong><br/>
                1️⃣ 请在收到邮件 24 小时内验证该指令的真实性<br/>
                2️⃣ 此邮件包含加密验证信息，请勿转发给他人<br/>
                3️⃣ 对指令内容如有疑问，请联系相关权威部门<br/>
                4️⃣ 此系统由 StillHere 自动驱动，不涉及任何人工干预
            </div>

            <div class="info-block">
                <div class="info-label">📋 记录编号</div>
                <div class="info-value">${recordDoc.id}</div>
            </div>
        </div>

        <div class="footer">
            <p>StillHere Digital Legacy System | 完全自动化驱动</p>
            <p>© 2024-2026 StillHere. <a href="https://stillhere.vercel.app">查看隐私政策</a></p>
            <p style="margin-top: 15px; color: #888;">本邮件由系统自动生成，请勿直接回复</p>
        </div>
    </div>
</body>
</html>`;

                    const mailOptions = {
                        from: `"StillHere 遗产系统" <${process.env.GMAIL_USER}>`,
                        to: record.heirEmail,
                        subject: `【紧急执行】来自 ${userData.email || '用户'} 的数字遗产指令 - ${record.title}`,
                        html: htmlContent,
                        text: `【${record.title}】\n\n${record.content}\n\n---\n验证码: ${verificationCode}\n本指令由 StillHere 系统自动分发。`,
                        headers: {
                            'X-StillHere-Verification': verificationCode,
                            'X-StillHere-Signature': messageSignature,
                            'X-StillHere-User-ID': uid,
                            'X-StillHere-Record-ID': recordDoc.id,
                            'X-Priority': '1',
                            'Importance': 'high'
                        }
                    };

                    try {
                        await transporter.sendMail(mailOptions);
                        
                        // 记录发送结果到数据库
                        await recordDoc.ref.update({
                            sentAt: now,
                            sentTo: record.heirEmail,
                            verificationCode: crypto
                                .createHash('sha256')
                                .update(verificationCode)
                                .digest('hex'),
                            messageSignature: messageSignature,
                            status: 'delivered'
                        });
                        
                        logger.log(`✅ [发送成功] 继承人: ${record.heirEmail} | 标题: ${record.title}`);
                    } catch (mailErr) {
                        // 记录发送失败
                        await recordDoc.ref.update({
                            failedAt: now,
                            failureReason: mailErr.message,
                            status: 'failed'
                        });
                        
                        logger.error(`❌ [发送失败] 用户 ${uid} 的指令 "${record.title}": ${mailErr.message}`);
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

// HTTP 函数：代理 Firebase Storage 请求以解决 CORS 问题
// 配置 CORS
const corsHandler = cors({ origin: true });

exports.proxyImage = onRequest((req, res) => {
    corsHandler(req, res, async () => {
        try {
            if (req.method === 'OPTIONS') {
                res.status(200).send('');
                return;
            }
            
            if (req.method !== 'GET') {
                res.status(405).send('Method not allowed');
                return;
            }
            
            const { url } = req.query;
            
            if (!url) {
                res.status(400).json({ error: 'Missing url parameter' });
                return;
            }
            
            // 解码 URL
            let imageUrl;
            try {
                imageUrl = decodeURIComponent(url);
            } catch (e) {
                res.status(400).json({ error: 'Invalid URL encoding' });
                return;
            }
            
            // 验证 URL 来自 Firebase Storage
            if (!imageUrl.includes('firebasestorage.googleapis.com')) {
                res.status(403).json({ error: 'Invalid URL - must be from Firebase Storage' });
                return;
            }
            
            logger.info('Proxy requesting image from:', imageUrl.substring(0, 80) + '...');
            
            // 获取图片
            const response = await fetch(imageUrl, {
                timeout: 30000,
                headers: {
                    'User-Agent': 'Mozilla/5.0 (compatible; StillHereApp/1.0)'
                }
            });
            
            if (!response.ok) {
                logger.error('Failed to fetch image:', response.status, response.statusText);
                res.status(response.status).json({ 
                    error: `Failed to fetch image: ${response.statusText}` 
                });
                return;
            }
            
            // 获取内容类型
            const contentType = response.headers.get('content-type') || 'image/jpeg';
            
            // 获取图像数据
            const buffer = await response.arrayBuffer();
            
            // 设置响应头
            res.set('Content-Type', contentType);
            res.set('Content-Length', buffer.byteLength.toString());
            res.set('Cache-Control', 'public, max-age=3600');
            res.set('X-Content-Type-Options', 'nosniff');
            
            // 发送二进制数据
            res.status(200).send(Buffer.from(buffer));
            
            logger.info('Image proxied successfully from:', imageUrl.substring(0, 80) + '...');
            
        } catch (error) {
            logger.error('Proxy error:', error.message, error.stack);
            res.status(500).json({ 
                error: 'Internal server error',
                message: error.message 
            });
        }
    });
});