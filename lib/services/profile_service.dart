import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'session_service.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  // Get current user profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data == null) return null;

      final postsSnap = await _db
          .collection('posts')
          .where('user_id', isEqualTo: user.uid)
          .get();

      return {
        ...data,
        'id': user.uid,
        'post_count': postsSnap.docs.length,
      };
    } catch (_) {
      return null;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  // Upload profile picture to Firebase Storage with Firestore fallback
  Future<Map<String, dynamic>> uploadProfilePicture(XFile image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final imageBytes = await image.readAsBytes();
      if (imageBytes.isEmpty) {
        return {'success': false, 'message': 'Selected image is empty'};
      }

      String? publicUrl;
      String? storageErrorDetails;

      // 1. Attempt upload to Firebase Storage
      try {
        final ref = _storage.ref('profiles/${user.uid}/profile.jpg');
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        if (kIsWeb) {
          await ref.putData(imageBytes, metadata);
        } else {
          await ref.putFile(File(image.path), metadata);
        }
        publicUrl = await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        storageErrorDetails = 'Firebase Storage (${e.code}): ${e.message ?? 'Bucket not found'}';
      } catch (e) {
        storageErrorDetails = 'Storage error: $e';
      }

      // 2. If Firebase Storage upload succeeded
      if (publicUrl != null && publicUrl.isNotEmpty) {
        await _db.collection('users').doc(user.uid).set({
          'profile_picture_url': publicUrl,
        }, SetOptions(merge: true));

        try {
          await user.updatePhotoURL(publicUrl);
          await user.reload();
        } catch (_) {}

        return {'success': true, 'url': publicUrl};
      }

      // 3. Fallback: Firebase Storage bucket is not provisioned (HTTP 404 / Spark plan)
      // Save compressed image data URI in Firestore user profile
      try {
        final base64String = base64Encode(imageBytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';

        await _db.collection('users').doc(user.uid).set({
          'profile_picture_url': dataUri,
        }, SetOptions(merge: true));

        if (dataUri.length <= 2048) {
          try {
            await user.updatePhotoURL(dataUri);
            await user.reload();
          } catch (_) {}
        }

        return {
          'success': true,
          'url': dataUri,
          'fallback': true,
        };
      } catch (firestoreError) {
        return {
          'success': false,
          'message': storageErrorDetails != null
              ? '$storageErrorDetails\nFallback failed: $firestoreError'
              : 'Failed to upload image: $firestoreError',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload image: $e'};
    }
  }

  // Remove profile picture
  Future<Map<String, dynamic>> removeProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      try {
        final ref = _storage.ref('profiles/${user.uid}/profile.jpg');
        await ref.delete().catchError((_) {});
      } catch (_) {}

      await _db.collection('users').doc(user.uid).set({
        'profile_picture_url': null,
      }, SetOptions(merge: true));

      try {
        await user.updatePhotoURL(null);
        await user.reload();
      } catch (_) {}

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove image: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    await SessionService().onLogout();
    await _auth.signOut();
  }
}