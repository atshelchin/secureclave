# 📋 Prerequisites Checklist

## 🔐 Secure Enclave Prerequisites

### ✅ Required Conditions
1. **Physical Device**
   - ❌ Simulator: Secure Enclave NOT available
   - ✅ iPhone 5s or later (A7 chip or newer)
   - ✅ iPad Air or later
   - ✅ Mac with T1/T2 chip

2. **iOS Version**
   - Minimum: iOS 11.0 (CryptoKit available)
   - Recommended: iOS 13.0+ (Full features)

3. **Device Security**
   - Device passcode must be set (optional but recommended)
   - Biometric authentication enrolled (optional)
     - Touch ID or Face ID

### 🔑 Key Features & Limitations
- **Algorithm**: EC P-256 (EC256/secp256r1) ONLY
- **Key Size**: 256-bit
- **Private Key**: Cannot be exported, stays in hardware
- **Public Key**: Can be exported and shared
- **Persistence**: Keys survive app deletion
- **Backup**: NOT included in iCloud backup

### ⚠️ Common Issues
| Issue | Solution |
|-------|----------|
| "Secure Enclave not available" | Use physical device, not simulator |
| "Failed to create key" | Check device passcode is set |
| "Biometry required" error | Enroll Touch ID/Face ID |
| Keys lost after restore | Keys not backed up, this is by design |

---

## 🔑 Passkeys Prerequisites

### ✅ Required Conditions

1. **iOS Version**
   - ❌ iOS 15 or lower: Passkeys not supported
   - ✅ iOS 16.0+: Full Passkeys support
   - ✅ iOS 17.0+: Enhanced features

2. **Physical Device**
   - ⚠️ Simulator: Limited functionality
   - ✅ Physical iPhone/iPad: Full support

3. **Associated Domains Configuration**
   ```
   Entitlements:
   webcredentials:your-domain.com
   
   AASA File Location:
   https://your-domain.com/.well-known/apple-app-site-association
   
   AASA Content:
   {
     "webcredentials": {
       "apps": ["TEAMID.bundleid"]
     }
   }
   ```

4. **iCloud Account**
   - Optional but recommended for sync
   - Without iCloud: Device-only passkeys

5. **Network Connectivity**
   - Required for domain verification
   - Required for AASA file download

6. **Device Security**
   - Device passcode required
   - Biometric enrollment recommended

### 📱 Current App Configuration
```
Domain: atshelchin.github.io
Team ID: 9RS8E64FWL
Bundle ID: app.hotlabs.secureenclave
RP ID: atshelchin.github.io
```

### ⚠️ Common Issues

| Issue | Solution |
|-------|----------|
| Error 1001: "Operation couldn't be completed" | Check Associated Domains configuration |
| Error 1004: "No passkeys found" | Normal for first sign-in, create passkey first |
| "Failed: Check Associated Domains" | Verify AASA file is accessible |
| "Interrupted" error | Network issue, check connectivity |
| Passkey not syncing | Check iCloud signed in and Keychain sync enabled |
| "Database permission denied" | Entitlements issue, rebuild app |

### 🔍 Debugging Steps

1. **Verify AASA File**
   ```bash
   curl https://your-domain/.well-known/apple-app-site-association
   ```

2. **Check Entitlements**
   - Xcode → Target → Signing & Capabilities
   - Associated Domains: webcredentials:domain

3. **Test Device Requirements**
   - Settings → Face ID/Touch ID & Passcode
   - Settings → [Your Name] → Sign in with iCloud

4. **Monitor Logs**
   - Check Console.app for ASAuthorization errors
   - Enable detailed logging in PasskeysManager

---

## 🚀 Quick Start Checklist

### For Secure Enclave
- [ ] Using physical device
- [ ] Device has passcode
- [ ] iOS 11.0 or later
- [ ] Biometrics enrolled (optional)

### For Passkeys
- [ ] Using physical device
- [ ] iOS 16.0 or later
- [ ] Associated Domains configured
- [ ] AASA file deployed
- [ ] Team ID correct (9RS8E64FWL)
- [ ] Bundle ID correct (app.hotlabs.secureenclave)
- [ ] iCloud signed in (optional)
- [ ] Network connection available

---

## 📝 Testing Matrix

| Feature | Simulator | Physical Device | Requirements |
|---------|-----------|-----------------|--------------|
| **Secure Enclave** |
| Key Generation | ❌ | ✅ | Hardware chip |
| Sign/Verify | ❌ | ✅ | Hardware chip |
| Biometric Protection | ❌ | ✅ | Touch/Face ID |
| **Passkeys** |
| Create Credential | ⚠️ | ✅ | iOS 16+ |
| Sign In | ⚠️ | ✅ | iOS 16+ |
| iCloud Sync | ❌ | ✅ | iCloud account |
| AutoFill | ❌ | ✅ | iOS 16+ |

---

## 🛠 Troubleshooting Commands

### Check Secure Enclave Availability
```swift
if SecureEnclave.isAvailable {
    print("✅ Secure Enclave available")
} else {
    print("❌ Secure Enclave NOT available")
}
```

### Verify Associated Domains
```bash
# Check AASA file
curl -I https://atshelchin.github.io/.well-known/apple-app-site-association

# Validate JSON format
curl https://atshelchin.github.io/.well-known/apple-app-site-association | python -m json.tool
```

### Test Passkeys Domain
```swift
// In PasskeysManager
let domain = "atshelchin.github.io"
let rpID = "atshelchin.github.io"
print("Domain: \(domain)")
print("RP ID: \(rpID)")
```

---

## 📊 Feature Comparison

| Aspect | Secure Enclave | Passkeys |
|--------|----------------|----------|
| **Purpose** | Hardware key storage | Passwordless auth |
| **Algorithm** | EC P-256 only | ES256 (P-256) |
| **Private Key Location** | Hardware only | Hardware + sync |
| **Public Key Access** | Exportable | One-time access |
| **Backup Support** | No | Yes (via iCloud) |
| **Cross-Device** | No | Yes (with iCloud) |
| **Biometric Required** | Optional | Yes |
| **Network Required** | No | Yes (verification) |
| **Min iOS Version** | 11.0 | 16.0 |

---

## 💡 Best Practices

1. **Always test on physical devices** for production features
2. **Save public keys immediately** - Passkeys only show once
3. **Use SwiftData with CloudKit** for data persistence
4. **Implement proper error handling** with detailed logging
5. **Check prerequisites at app launch** to inform users
6. **Provide fallback options** when features unavailable