import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseMFAService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Enroll phone number for MFA
  static Future<Map<String, dynamic>> enrollPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      // Start phone verification
      await user.multiFactor.getSession().then((session) async {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          multiFactorSession: session,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification (Android only)
            try {
              await _enrollWithCredential(credential);
              if (kDebugMode) print('Auto-verification successful');
            } catch (e) {
              onError('Auto-verification failed: $e');
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (kDebugMode) print('Verification failed: ${e.message}');
            onError(e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            if (kDebugMode) print('Code sent to $phoneNumber');
            onCodeSent(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (kDebugMode) print('Auto-retrieval timeout');
          },
        );
      });

      return {'success': true};
    } catch (e) {
      if (kDebugMode) print('Enroll error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Complete enrollment with verification code
  static Future<Map<String, dynamic>> completeEnrollment({
    required String verificationId,
    required String smsCode,
    String displayName = 'Phone Number',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      // Create phone credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _enrollWithCredential(credential, displayName: displayName);

      return {'success': true, 'message': 'Phone MFA enabled successfully'};
    } catch (e) {
      if (kDebugMode) print('Complete enrollment error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Helper to enroll with credential
  static Future<void> _enrollWithCredential(
    PhoneAuthCredential credential, {
    String displayName = 'Phone Number',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(credential);
    await user.multiFactor.enroll(multiFactorAssertion, displayName: displayName);
  }

  // Verify MFA during sign-in
  static Future<Map<String, dynamic>> verifyMFACode({
    required MultiFactorResolver resolver,
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final multiFactorAssertion = PhoneMultiFactorGenerator.getAssertion(credential);
      final userCredential = await resolver.resolveSignIn(multiFactorAssertion);

      return {
        'success': true,
        'user': userCredential.user,
      };
    } catch (e) {
      if (kDebugMode) print('Verify MFA error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Send MFA code during sign-in
  static Future<Map<String, dynamic>> sendMFACode({
    required MultiFactorResolver resolver,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final hint = resolver.hints.first;
      
      if (hint is! PhoneMultiFactorInfo) {
        return {'success': false, 'error': 'Invalid MFA method'};
      }

      await _auth.verifyPhoneNumber(
        multiFactorSession: resolver.session,
        multiFactorInfo: hint,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification
          try {
            final result = await verifyMFACode(
              resolver: resolver,
              verificationId: '',
              smsCode: credential.smsCode ?? '',
            );
            if (kDebugMode) print('Auto-verification result: $result');
          } catch (e) {
            onError('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) print('Auto-retrieval timeout');
        },
      );

      return {'success': true};
    } catch (e) {
      if (kDebugMode) print('Send MFA code error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Unenroll (disable) MFA
  static Future<Map<String, dynamic>> unenrollMFA({
    required String factorUid,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      await user.multiFactor.unenroll(factorUid: factorUid);

      return {'success': true, 'message': 'MFA disabled successfully'};
    } catch (e) {
      if (kDebugMode) print('Unenroll error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get enrolled factors
  static Future<List<MultiFactorInfo>> getEnrolledFactors() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    try {
      final enrolledFactors = await user.multiFactor.getEnrolledFactors();
      return enrolledFactors;
    } catch (e) {
      if (kDebugMode) print('Get enrolled factors error: $e');
      return [];
    }
  }

  // Check if MFA is enabled
  static Future<bool> isMFAEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final enrolledFactors = await user.multiFactor.getEnrolledFactors();
      return enrolledFactors.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Check MFA status error: $e');
      return false;
    }
  }
}
