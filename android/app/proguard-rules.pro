# Keep Stripe classes
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }

# Keep push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }

# Dontwarn for missing classes
-dontwarn com.stripe.android.pushProvisioning.**
