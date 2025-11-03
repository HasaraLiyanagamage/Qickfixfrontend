# Google Maps Setup Instructions

## Current Status
⚠️ **Google Maps is currently disabled** due to billing not being enabled on the API key.

The app will work with a fallback UI showing tracking information without the map view.

---

## How to Enable Google Maps

### Step 1: Enable Billing in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project: **quickfixapp-3074a**
3. Navigate to **Billing** from the left menu
4. Click **Link a billing account**
5. Follow the prompts to add a payment method

### Step 2: Enable Required APIs

1. In Google Cloud Console, go to **APIs & Services** → **Library**
2. Search for and enable the following APIs:
   - **Maps JavaScript API**
   - **Maps SDK for Android** (for Android app)
   - **Maps SDK for iOS** (for iOS app)
   - **Places API** (if using place autocomplete)
   - **Directions API** (if using route directions)

### Step 3: Configure API Key Restrictions

1. Go to **APIs & Services** → **Credentials**
2. Find your API key: `AIzaSyCuM0azsWGgHBDxEPMFePt35xzPY20FFLc`
3. Click on the key to edit it
4. Under **Application restrictions**:
   - For web: Select **HTTP referrers** and add your domains
   - For mobile: Select **Android apps** or **iOS apps** and add package names
5. Under **API restrictions**:
   - Select **Restrict key**
   - Choose the APIs you enabled in Step 2
6. Click **Save**

### Step 4: Enable Google Maps in the App

Once billing is enabled and APIs are configured:

1. Open `web/index.html`
2. Find the commented Google Maps script (around line 56-66)
3. Uncomment this line:
   ```html
   <script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCuM0azsWGgHBDxEPMFePt35xzPY20FFLc&libraries=places"></script>
   ```
4. Open `lib/screens/tracking_screen.dart`
5. Find line 44 and change:
   ```dart
   bool _mapError = true; // Set to true by default until Google Maps billing is enabled
   ```
   To:
   ```dart
   bool _mapError = false;
   ```
6. Save both files and restart your app

---

## API Keys in Your Project

Your project uses different API keys for different platforms:

- **Web (Google Maps)**: `AIzaSyCuM0azsWGgHBDxEPMFePt35xzPY20FFLc`
- **Firebase (Web/Mobile)**: `AIzaSyASXpbLwjfrt0Hu0nveTrCTbFhSV502m30`
- **Android (Google Maps)**: `AIzaSyCuM0azsWGgHBDxEPMFePt35xzPY20FFLc`
- **iOS (Firebase)**: `AIzaSyBwMLXDxeY4bOofi6th6ZPx7LbT20S_IYU`

Make sure to enable billing for the Google Cloud project associated with these keys.

---

## Cost Estimates

Google Maps Platform offers:
- **$200 free credit per month**
- Maps JavaScript API: $7 per 1,000 loads (after free tier)
- Most small to medium apps stay within the free tier

Learn more: [Google Maps Pricing](https://mapsplatform.google.com/pricing/)

---

## Troubleshooting

### Error: "BillingNotEnabledMapError"
- **Cause**: Billing is not enabled for your Google Cloud project
- **Solution**: Follow Step 1 above

### Error: "ApiNotActivatedMapError"
- **Cause**: Maps JavaScript API is not enabled
- **Solution**: Follow Step 2 above

### Error: "RefererNotAllowedMapError"
- **Cause**: Your domain/app is not authorized to use this API key
- **Solution**: Follow Step 3 above

### Map shows but is grayed out
- **Cause**: API key restrictions are too strict
- **Solution**: Temporarily remove restrictions in Step 3, test, then add them back properly

---

## Support

For more help, visit:
- [Google Maps JavaScript API Documentation](https://developers.google.com/maps/documentation/javascript)
- [Error Messages Reference](https://developers.google.com/maps/documentation/javascript/error-messages)
