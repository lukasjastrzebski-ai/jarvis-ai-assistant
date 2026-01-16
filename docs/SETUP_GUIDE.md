# Jarvis AI Assistant - Setup Guide

This guide walks you through setting up all external services and credentials needed to run Jarvis.

## Quick Start

```bash
# 1. Copy environment templates
cp .env.example .env
cp backend/.env.example backend/.env
cp backend/wrangler.toml.example backend/wrangler.toml
cp Config.xcconfig.example Config.xcconfig
cp src/JarvisCore/Config/Secrets.swift.example src/JarvisCore/Config/Secrets.swift

# 2. Fill in your credentials (see sections below)

# 3. Run the app
swift build
swift test
```

---

## 1. Google Cloud Setup (Gmail & Calendar)

### Create Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project named "Jarvis"
3. Note your **Project ID**

### Enable APIs
1. Go to **APIs & Services > Library**
2. Search and enable:
   - Gmail API
   - Google Calendar API

### Create OAuth Credentials
1. Go to **APIs & Services > Credentials**
2. Click **Create Credentials > OAuth client ID**
3. Select **iOS** as application type
4. Enter your Bundle ID: `com.yourcompany.jarvis`
5. Download the credentials JSON
6. Copy values to your config files:
   - `GOOGLE_CLIENT_ID` → Client ID
   - `GOOGLE_CLIENT_SECRET` → Client Secret

### Configure OAuth Consent Screen
1. Go to **OAuth consent screen**
2. Select **External** user type
3. Fill in app information
4. Add scopes:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/calendar.readonly`
   - `https://www.googleapis.com/auth/calendar.events`

---

## 2. OpenAI Setup (Embeddings)

### Get API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Navigate to **API Keys**
3. Create new secret key
4. Copy to `OPENAI_API_KEY` in your config

### Recommended Model
- Use `text-embedding-3-small` for cost efficiency
- Use `text-embedding-3-large` for better quality

---

## 3. Cloudflare Workers Setup (Backend)

### Install Wrangler
```bash
npm install -g wrangler
wrangler login
```

### Create D1 Database
```bash
cd backend
wrangler d1 create jarvis-db
```
Copy the `database_id` to `wrangler.toml`

### Set Secrets
```bash
wrangler secret put JWT_SECRET
wrangler secret put GOOGLE_CLIENT_ID
wrangler secret put GOOGLE_CLIENT_SECRET
wrangler secret put OPENAI_API_KEY
```

### Deploy
```bash
wrangler deploy
```

---

## 4. Apple Developer Setup

### Prerequisites
- Apple Developer Program membership ($99/year)
- Xcode installed

### App ID Registration
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, IDs & Profiles**
3. Create new **App ID**
   - Bundle ID: `com.yourcompany.jarvis`
   - Enable capabilities: Push Notifications, Sign in with Apple

### Provisioning Profile
1. Create **Development** provisioning profile
2. Create **Distribution** provisioning profile
3. Download and install in Xcode

---

## 5. iOS App Configuration

### Option A: Using Config.xcconfig
1. Copy `Config.xcconfig.example` to `Config.xcconfig`
2. Fill in all values
3. In Xcode, set as configuration file for your target

### Option B: Using Secrets.swift
1. Copy `Secrets.swift.example` to `Secrets.swift`
2. Fill in all values
3. File is auto-ignored by git

### URL Schemes
Add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## 6. Local Development

### Run Backend Locally
```bash
cd backend
npm install
wrangler dev
```
Backend runs at `http://localhost:8787`

### Run iOS App
```bash
# Build
swift build

# Test
swift test

# Or open in Xcode
open Package.swift
```

---

## Environment Files Summary

| File | Purpose | Git Ignored |
|------|---------|-------------|
| `.env` | Root project config | Yes |
| `backend/.env` | Backend local dev | Yes |
| `backend/wrangler.toml` | Cloudflare config | No* |
| `Config.xcconfig` | Xcode build config | Yes |
| `Secrets.swift` | Swift runtime secrets | Yes |

*wrangler.toml doesn't contain secrets directly (use `wrangler secret`)

---

## Troubleshooting

### "Invalid OAuth client" error
- Verify Bundle ID matches exactly
- Check OAuth consent screen is configured
- Ensure APIs are enabled

### "Database not found" error
- Run `wrangler d1 create jarvis-db`
- Verify database_id in wrangler.toml
- Run migrations: `wrangler d1 execute jarvis-db --file=./schema.sql`

### Build fails with missing Secrets
- Ensure `Secrets.swift` exists (not just `.example`)
- Check all required values are filled in

---

## Security Checklist

- [ ] All `.example` files copied and filled
- [ ] Original files added to `.gitignore`
- [ ] No secrets in source control
- [ ] OAuth consent screen configured
- [ ] API keys have appropriate restrictions
- [ ] Backend secrets set via `wrangler secret`
