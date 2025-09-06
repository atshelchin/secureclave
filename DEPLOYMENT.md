# Deployment Instructions for Passkeys Support

## GitHub Pages Setup for Passkeys

To enable Passkeys functionality, you need to deploy the Apple App Site Association file to your GitHub Pages site at https://atshelchin.github.io/

### Steps:

1. **Create/Update Your GitHub Pages Repository**
   - Repository name should be: `atshelchin.github.io`
   - Enable GitHub Pages in repository settings

2. **Deploy the Apple App Site Association File**
   
   Create the following directory structure in your GitHub Pages repository:
   ```
   atshelchin.github.io/
   └── .well-known/
       └── apple-app-site-association
   ```

3. **Upload the Configuration File**
   
   Copy the file from `well-known-config/apple-app-site-association` to your GitHub Pages repository:
   
   ```json
   {
     "webcredentials": {
       "apps": [
         "9RS8E64FWL.app.hotlabs.secureenclave"
       ]
     }
   }
   ```

4. **Configure Jekyll (Important!)**
   
   Create a `.nojekyll` file in the root of your GitHub Pages repository to prevent Jekyll from ignoring the `.well-known` directory.

5. **Add _config.yml**
   
   Create `_config.yml` in your repository root:
   ```yaml
   include: [".well-known"]
   ```

6. **Verify Deployment**
   
   After deployment, verify the file is accessible at:
   ```
   https://atshelchin.github.io/.well-known/apple-app-site-association
   ```

   The file should be served with:
   - Content-Type: `application/json` or `text/plain`
   - No redirects
   - HTTPS only

## Testing Passkeys

1. **Prerequisites**
   - iOS 16+ or macOS 13+ device
   - iCloud Keychain enabled
   - Same Apple ID signed in

2. **First Run**
   - Launch the app
   - Navigate to "Passkeys" section
   - Tap "Create Passkey"
   - Authenticate with Face ID/Touch ID
   - The passkey will be saved to iCloud Keychain

3. **Sign In Testing**
   - Tap "Sign In with Passkey"
   - Select from available passkeys
   - Authenticate with biometrics

## iCloud Sync Configuration

The app is configured to automatically sync data to iCloud using CloudKit. Ensure:

1. **Developer Account Settings**
   - CloudKit container is created: `iCloud.app.hotlabs.secureenclave`
   - Automatic schema generation is enabled

2. **Testing iCloud Sync**
   - Install app on multiple devices with same Apple ID
   - Create keys on one device
   - Check "iCloud Sync Debug" view on another device
   - Data should appear within minutes

## Troubleshooting

### Passkeys Not Working
- Verify apple-app-site-association is accessible
- Check entitlements match Bundle ID
- Ensure Associated Domains capability is enabled

### iCloud Sync Issues
- Check iCloud account is signed in
- Verify CloudKit container exists
- Check network connectivity
- Review logs in CloudSyncDebugView

### Secure Enclave Errors
- Only works on physical devices (not simulator)
- Requires devices with Secure Enclave chip
- Check biometric enrollment status