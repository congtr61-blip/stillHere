### 🔧 Configuration
- **Flutter:** Build using `flutter build web --release`.
- **Backend:** Firebase Cloud Functions (v2) with scheduled triggers.
- **Security:** Sensitive credentials managed via `.env` and excluded from version control.
- Focus: Functionality, Tech Stack, and Reliability.

StillHere: Automated Digital Legacy & Instruction System
StillHere is a Flutter-based web application integrated with Firebase, designed to ensure your critical instructions and digital legacy are delivered even if you are unable to do so manually.

The Concept: The user maintains a "Heartbeat" by interacting with the app. If the heartbeat stops for a predefined period (72 hours), the system automatically triggers.

Core Features:

Dead Man's Switch: Secure "Heartbeat" monitoring via Firebase Cloud Functions.

Automated Dispatch: Preset instructions (records) are sent to designated heirs via encrypted email upon signal loss.

Minimalist Dashboard: A high-contrast, biometric-themed UI for status monitoring.

Tech Stack: Flutter (Web), Firebase Firestore, Cloud Functions (Node.js), and Nodemailer.
