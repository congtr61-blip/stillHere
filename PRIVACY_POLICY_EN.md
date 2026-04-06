# Privacy Policy

**Effective Date:** April 5, 2026  
**Last Updated:** April 5, 2026  
**Product:** StillHere Application

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [What Data We Collect](#what-data-we-collect)
3. [How We Collect Data](#how-we-collect-data)
4. [How We Use Your Data](#how-we-use-your-data)
5. [Data Protection](#data-protection)
6. [Data Sharing](#data-sharing)
7. [Your Rights](#your-rights)
8. [Data Retention](#data-retention)
9. [Children's Privacy](#childrens-privacy)
10. [Third-Party Services](#third-party-services)
11. [Policy Changes](#policy-changes)
12. [Contact Us](#contact-us)

---

## Overview

Welcome to StillHere (hereinafter referred to as "the Application"). We value your privacy and are committed to being transparent about how we collect, use, and protect your personal information.

**In Simple Terms:**
- We only collect personal information necessary to provide our services
- We do not sell your data to third parties
- You can request access, modification, or deletion of your data at any time
- We use industry-standard encryption and security measures to protect your data

---

## What Data We Collect

### 1. Authentication Information

#### Phone Number
- **What it is:** The telephone number you use for registration and login
- **Why we collect it:**
  - User identity authentication
  - Sending SMS verification codes
  - Account recovery
- **Where it's stored:** Firestore Database
- **Encryption:** ✅ Encrypted at rest

#### Email Address
- **What it is:** The email address you provide
- **Why we collect it:**
  - Account registration and login
  - Email verification and confirmation
  - Account security notifications
  - Account recovery
- **Where it's stored:** Firestore Database and Firebase Authentication
- **Encryption:** ✅ Encrypted at rest

#### Google Account Information
- **What it is:** Information collected when you sign in with Google
  - Google User ID
  - Email address
  - Name (if provided)
  - Profile photo (if provided)
- **Why we collect it:**
  - User authentication
  - Account linking
- **Where it's stored:** Firebase Authentication and Firestore
- **Encryption:** ✅ Google-encrypted

### 2. Verification Data

#### SMS Verification Code
- **What it is:** 6-digit code sent to your phone
- **Why we collect it:** To verify phone number ownership
- **Retention:** Only during verification process; deleted immediately after
- **Encryption:** ✅ Encrypted in transit

#### Email Verification Link
- **What it is:** Email link containing a verification token
- **Why we collect it:** To verify email address ownership
- **Validity Period:** 24 hours
- **Encryption:** ✅ Token encrypted

### 3. Account Data

#### Contact Information
- **Stored information:**
  - Phone number and verification status
  - Email address and verification status
  - Google account linking status
- **Why we collect it:** Account management and contact method handling
- **Storage location:** Firestore Database

#### Account Linking Records
- **What it is:** Records of when multiple authentication methods are linked to the same account
- **Why we collect it:**
  - Prevent duplicate accounts
  - Enhance account security
  - Account recovery
- **Storage location:** Firestore Database
- **Encryption:** ✅ Encrypted

### 4. Technical Data

#### Device Identifiers
- **What it is:**
  - Device ID
  - Operating system version
  - Application version
- **Why we collect it:**
  - Debugging and troubleshooting
  - Application optimization
  - Security audits
- **Storage location:** Firebase Logs

#### Usage Data
- **What it is:**
  - Application feature usage
  - Error logs
  - Performance metrics
- **Why we collect it:**
  - Improve application performance
  - Identify and fix issues
  - Optimize user experience
- **Storage location:** Firebase Logging / Crashlytics

#### IP Address
- **What it is:** Your IP address when accessing the application
- **Why we collect it:**
  - Security protection (detect unusual logins)
  - Server logging
- **Storage location:** Firebase server logs
- **Use:** NOT used for physical location tracking

---

## How We Collect Data

### Direct Collection

We directly collect the following information from you:
- Phone number and email you provide during registration
- Verification codes you enter during email verification
- Google account you choose to link

### Automatic Collection

When you use the application, we automatically collect:
- Device information
- Usage logs
- Error reports
- Performance data

### Third-Party Collection

Through the following services:
- Google Firebase (authentication, database, logging)
- Google Analytics (optional)

---

## How We Use Your Data

We only use your personal data for the following purposes:

### 1. Provide Core Services
- User authentication and verification
- Account management
- Contact method management
- Account security

### 2. Security and Fraud Prevention
- Detect suspicious activity
- Prevent unauthorized access
- Security audits
- Breach investigation

### 3. Customer Support
- Account recovery
- Technical support
- Identity verification

### 4. Service Improvement
- Analyze application performance
- Identify and fix bugs
- Optimize user experience
- Develop new features

### 5. Legal Compliance
- Comply with legal requirements
- Protect our rights
- Resolve disputes

### ❌ We Do NOT Use Your Data For:
- Sending marketing emails (without your consent)
- Selling your data to third parties
- Purposes outside the core application services (without consent)
- Physical location tracking

---

## Data Protection

### Encryption

**All Transmissions:** ✅ TLS/SSL encrypted
- All network communication uses HTTPS encryption
- Data transmitted between servers is encrypted

**Static Storage:** ✅ Database encryption
- Firebase automatically encrypts data stored in Firestore
- Sensitive information (like passwords) uses industry-standard encryption

### Access Control

**Authentication:**
- Firebase Authentication handles all user authentication
- Only authenticated users can access their own data
- Server-side validation for all requests

**Authorization Rules:**
```javascript
// Firestore Security Rules example:
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

match /contacts/{userId} {
  allow read, write: if request.auth.uid == userId;
}
```

This means:
- Users can only access their own data
- Other users cannot see your information
- Administrators cannot read your data

### Security Measures

✅ **Implemented Security Measures:**
- Regular security audits
- Firewalls and DDoS protection (provided by Google Cloud)
- Encryption key management
- Logging and monitoring
- Secure password handling

### Data Backup

- Firebase automatically backs up all data
- Backups are also encrypted
- Backups are stored in secure geographic locations

---

## Data Sharing

### We DO NOT Share Your Personal Data With:

❌ **Marketing Companies** - We do not sell your data for marketing purposes

❌ **Data Brokers** - We do not share with any third-party data brokers

❌ **Advertising Networks** - We do not share personally identifiable information with ad networks

### We Do Share Data With (Only When Necessary):

✅ **Firebase Services**
- Google's infrastructure services
- Used for authentication, data storage, logging
- Google complies with industry-standard data processing protocols

✅ **Law Enforcement**
- Only when legally required (court orders, search warrants, etc.)
- We will notify you when possible

✅ **Business Partners**
- Only for services you explicitly consent to
- These partners are bound by confidentiality agreements

### International Data Transfers

Your data may be stored in different geographic locations, including:
- United States (Firebase default region)
- European Union (if you select it)

All international transfers are protected by:
- Standard Contractual Clauses (SCCs)
- Data Processing Agreements

---

## Your Rights

Under applicable privacy laws (including GDPR and other regional laws), you have the following rights:

### 1. Right to Access 🔍
- **Right:** Request access to all personal data we hold about you
- **How to exercise:** Email privacy@stillhere.app (identity verification required)
- **Timeframe:** We will respond within 30 days

### 2. Right to Correction ✏️
- **Right:** Request correction if your data is inaccurate or incomplete
- **Examples:** Email change, phone number update
- **How to exercise:** Modify directly in the app or submit a request
- **Timeframe:** Effective immediately

### 3. Right to Deletion 🗑️
- **Right:** Request deletion of your data in certain circumstances
- **Exceptions:** We may retain data to comply with legal obligations or protect our rights
- **How to exercise:**
  - Select "Delete Account" in the app
  - Or email privacy@stillhere.app
- **Timeframe:** Complete within 30 days unless legal obstacles exist

### 4. Right to Data Portability 📤
- **Right:** Receive your data in a structured, commonly used, machine-readable format
- **Purpose:** Transfer your data to other services
- **How to exercise:** Email privacy@stillhere.app
- **Format:** JSON or CSV

### 5. Right to Object 🛑
- **Right:** Object to our use of your data in certain circumstances
- **Limitation:** May impact our ability to provide services

### 6. Right to Restrict 👮
- **Right:** Request restriction of processing your data
- **When to use:** When you believe data is inaccurate or processing is unlawful

### 7. Right to Withdraw Consent ↩️
- **Right:** Withdraw previously given consent
- **Impact:** May affect our ability to provide certain services

### How to Exercise Your Rights

**Method 1: In-App**
1. Open the app menu
2. Select "Account Settings" or "Privacy"
3. Choose the appropriate action

**Method 2: Email**
```
To: privacy@stillhere.app
Subject: Data Privacy Request - [Your Request Type]

Include:
- Your registered email or phone number
- Your specific request
- Identity verification information
```

**Method 3: In-App Message**
- Use the in-app feedback feature
- We will confirm receipt within 24 hours

**Response Timeframe:** Within 30 days

---

## Data Retention

### How Long Do We Keep Your Data?

#### While Account is Active
- All account data is retained while you use the account
- This includes phone number, email, verification status, etc.

#### After Account Deletion
- **Deleted Immediately:**
  - All personally identifiable information
  - Contact methods
  - Verification records

- **Retained for 30 Days (for recovery):**
  - Account data (in case you need account recovery)
  - Permanently deleted after 30 days

- **Retained for Legal Duration Requirements:**
  - Transaction logs (tax and legal requirements, typically 7 years)
  - Security audit logs (1 year)
  - Litigation-related data (until litigation is resolved)

#### Inactive Accounts
- If your account is inactive for 12 months, we will:
  - Send a reminder email
  - Give you 30 days to continue using the account
  - After 30 days, your account is considered inactive
  - Data from inactive accounts is deleted after 12 months

### Data Minimization

We follow the "data minimization" principle:
- Collect only data necessary to provide services
- Regularly review and delete unnecessary data
- Do not retain data "for future use"

---

## Children's Privacy

### Our Policy for Children

✋ **StillHere Application is not intended for children under 13 years old.**

**Key Points:**
- We do not intentionally collect personal information from children under 13
- We comply with COPPA (Children's Online Privacy Protection Act)
- If you are under 13, please do not create an account
- If you are a parent/guardian and discover your child registered, please notify us

### Teenagers 13-18 Years Old

- We comply with applicable teenage privacy laws
- We recommend parents supervise teenage accounts
- Teenagers have the same privacy rights

### If You Discover a Compliance Issue

Please contact immediately: privacy@stillhere.app

---

## Third-Party Services

### Google Firebase

We use Google Firebase to provide core application services.

**Firebase Services Used:**

#### 1. Firebase Authentication
- Handles user login and registration
- Manages password encryption
- Processes SMS verification codes

**How Google Uses Your Data:**
- Verify user identity
- Securely store authentication credentials
- Provide login logs

**Privacy Policy:** https://policies.google.com/privacy

#### 2. Cloud Firestore
- Store your account data
- Store your contact methods
- Store your verification status

**How Google Uses Your Data:**
- Store your data (encrypted)
- Perform routine backups
- Provide data access logs

#### 3. Firebase Cloud Logging
- Log application errors
- Log application usage
- Log performance metrics

**How Google Uses Your Data:**
- Identify and fix issues
- Optimize application performance
- Security audits

#### 4. Firebase Realtime Database (Optional)
- Real-time data synchronization
- Sync between devices

### Google Analytics (Optional)

If enabled, we use Google Analytics to:
- Analyze application usage patterns
- Improve user experience
- Identify content gaps

**Google Will NOT:**
- Identify your personal identity
- Share your personal data with third parties

### Other Third Parties

#### Sentry (Error Reporting, Optional)
- If enabled, captures application crashes
- Helps us fix issues

#### Firebase Performance Monitoring
- Monitor application speed
- Identify performance issues

### Third-Party Policies

You should read each third-party service's privacy policy:
- Google Privacy Policy: https://policies.google.com/privacy
- Google Terms of Service: https://policies.google.com/terms

We have agreements with these third parties ensuring they process your data according to this Privacy Policy.

---

## Policy Changes

### When We May Update This Policy

We may update this policy to:
- Reflect service changes
- Comply with new legal requirements
- Improve transparency
- Respond to user feedback

### What Notification You Will Receive

✉️ **If changes involve:**
- How we use your personal data (significant changes)
- New third-party partners (significant changes)
- Changes to your rights

**Notification Methods:**
- In-app notification
- Email (to registered email)
- Pop-up when opening the app

⏰ **Notification Timing:**
- Most changes: 30 days notice
- Emergency security changes: Immediate notice

### How to Respond to Changes

- ✅ **Agree:** Continue using the application
- ❌ **Disagree:** Delete your account (before changes take effect)

---

## Contact Us

### Privacy Questions

If you have questions about this Privacy Policy or want to exercise your data privacy rights, please contact:

**Email:**
```
privacy@stillhere.app
```

**Mailing Address:**
```
StillHere
Attn: Privacy Team
[Your Address]
```

**In-App Contact:**
- Open app menu → Help and Support → Privacy Issues

### Data Protection Officer

For GDPR-related issues:
```
Email: dpo@stillhere.app
```

### Regulatory Authorities

If you are not satisfied with our response to your privacy concerns, you have the right to lodge a complaint with the data protection authority in your region:

**European Union:**
- Your country/region's data protection authority
- EU Privacy Board: https://edpb.europa.eu/

**United States:**
- FTC (Federal Trade Commission): https://reportfraud.ftc.gov/

**Other Regions:** Please consult the privacy regulatory authority in your region

### Response Timeframe

We aim to respond to all privacy inquiries within:
- ✅ 24 hours: Confirmation of receipt
- ✅ 5 business days: Initial response
- ✅ 30 days: Complete response

---

## Other Important Information

### Cross-Border Data Transfers

Your data may be transferred, stored, and processed in countries different from where you are located. Privacy laws in these countries may differ.

**Our Commitment:**
- Use Standard Contractual Clauses (SCCs) for all international transfers
- Ensure adequate protection of your data
- Comply with GDPR and other regional privacy laws

### Security Limitations

While we implement extensive security measures, please note:
- There is no 100% secure system on the internet
- All data transmissions carry some risk
- We will do our best to protect your data

### Data Processing Agreement (DPA)

For businesses and organizations processing personal data, we provide a DPA:
- Details terms of data processing
- Ensures GDPR compliance
- Contact privacy@stillhere.app if you need a DPA

---

## Quick Reference Guide

### Frequently Asked Questions

**Q: Will you sell my phone number to marketing companies?**
A: No. We never sell any personal data.

**Q: What happens if I delete my account?**
A: All your personal data will be deleted. Only data legally required (such as tax records) will be retained per legal requirements.

**Q: Do you track my location?**
A: No. We collect IP addresses for security purposes but do not track your physical location.

**Q: How do I update my information?**
A: Select "Edit Profile" or "Account Settings" in the app and modify your information.

**Q: How will I know if my data is breached?**
A: If a security incident occurs, we will notify you via email within 72 hours.

**Q: What encryption do you use?**
A:
- Transit: TLS/SSL (HTTPS)
- Storage: AES-256 (Firebase standard encryption)
- Backup: Same encryption standards

**Q: Can third parties (like Google) see my data?**
A: Only the information they need to provide services. All sensitive data is encrypted.

---

## Summary

| Item | Answer |
|------|--------|
| Do we sell your data? | ❌ No |
| Do we track location? | ❌ No |
| Do we encrypt data? | ✅ Yes |
| Can you delete your data? | ✅ Yes |
| Can you access your data? | ✅ Yes |
| Can you modify your data? | ✅ Yes |
| Do we comply with GDPR? | ✅ Yes |
| Do we comply with CCPA? | ✅ Yes |

---

**Version:** 1.0  
**Effective Date:** April 5, 2026  
**Last Updated:** April 5, 2026

**© 2026 StillHere. All rights reserved.**
