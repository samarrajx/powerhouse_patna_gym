# 🏋️ Power House Gym

Power House Gym is a complete end-to-end gym management and attendance tracking platform. The system is split into three main components: a Node.js backend, a Flutter mobile app for members and admins, and a Vite/React web admin panel.

---

## 🏗️ Architecture

### 1. Backend (`/backend`)
A centralized Node.js/Express REST API serving both the mobile app and the web admin panel.
* **Database**: Supabase PostgreSQL
* **Push Notifications**: Firebase Cloud Messaging (FCM)
* **Auth**: JWT-based authentication
* **Features**: Automated cron jobs for session auto-checkout and membership renewal reminders, rate limiting, and security headers.

### 2. Mobile App (`/mobile/powerhouse_app`)
A cross-platform Flutter application tailored for both Gym Members and Gym Admins.
* **Member View**: Dashboard to track attendance, membership expiry, daily schedules, diet plans, and view gym status.
* **Admin View**: Dashboard to scan QR codes for attendance, freeze/unfreeze memberships, send global push announcements, and monitor live active gym capacity.
* **Key Integrations**: Firebase Push Notifications, shared_preferences for local caching.

### 3. Web Admin Panel (`/admin-web-panel`)
A React/Vite web application intended for the front desk / management.
* **Features**: Live dashboard of gym metrics, member onboarding, bulk CSV member upload, manual attendance override, and financial tracking.

---

## 🚀 Quick Setup

### Backend
\`\`\`bash
cd backend
npm install
# Add .env (contact admin for secrets)
npm run dev
\`\`\`

### Admin Web Panel
\`\`\`bash
cd admin-web-panel
npm install
npm run dev
\`\`\`

### Mobile App
\`\`\`bash
cd mobile/powerhouse_app
flutter pub get
flutter run
\`\`\`

---

## 🔒 Security & Production Guidelines
* This app uses a strict CORS policy limited to the production Vercel apps.
* `print()` statements are stripped out of the release Flutter app.
* All env secrets (Supabase keys, JWT secret, DB URLs) are stored in Vercel environment variables. **Never commit them to source.**

*Built with ❤️ for Power House Gym.*
