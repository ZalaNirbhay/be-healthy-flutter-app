import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Current User ───
  static User? get currentUser => _auth.currentUser;

  // ─── Get User Document ───
  static Future<Map<String, dynamic>?> getUserDocument() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // ─── Update User Document ───
  static Future<void> updateUserDocument(Map<String, dynamic> updates) async {
    try {
      final user = currentUser;
      if (user == null) return;

      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Sign-in cancelled'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      User user = userCredential.user!;

      DocumentReference userDoc =
          _firestore.collection('users').doc(user.uid);

      DocumentSnapshot doc = await userDoc.get();

      if (!doc.exists) {
        // 🔥 NEW USER — Store Google data including photo_url
        await userDoc.set({
          'name': user.displayName ?? "",
          'email': user.email ?? "",
          'photo_url': user.photoURL ?? "",
          'age': null,
          'gender': null,
          'height_cm': null,
          'weight_kg': null,
          'activity_level': null,
          'goal': null,
          'profile_completed': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        return {'success': true, 'profileCompleted': false};
      } else {
        // 🔥 EXISTING USER — Only update photo_url if empty
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String existingPhoto = data['photo_url'] ?? "";

        if (existingPhoto.isEmpty && (user.photoURL ?? "").isNotEmpty) {
          await userDoc.update({
            'photo_url': user.photoURL,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        bool completed = data['profile_completed'] ?? false;
        return {'success': true, 'profileCompleted': completed};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Google Sign-In failed'};
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In failed'};
    }
  }

  // ─── Email Sign-In ───
  static Future<Map<String, dynamic>> signInWithEmail(
      String email, String password) async {
    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        return {'success': false, 'message': 'Please fill in all fields'};
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        // Edge case: Auth user exists but no Firestore document
        await _firestore.collection('users').doc(uid).set({
          'name': userCredential.user!.displayName ?? "",
          'email': email.trim(),
          'photo_url': "",
          'profile_completed': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        return {'success': true, 'profileCompleted': false};
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      bool completed = data['profile_completed'] ?? false;

      return {'success': true, 'profileCompleted': completed};
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";

      if (e.code == 'user-not-found') {
        message = "No account found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      } else if (e.code == 'invalid-credential') {
        message = "Invalid email or password";
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login failed. Please try again.'};
    }
  }

  // ─── Email Registration ───
  static Future<Map<String, dynamic>> registerWithEmail(
      String name, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'photo_url': "",
        'age': null,
        'gender': null,
        'height_cm': null,
        'weight_kg': null,
        'activity_level': null,
        'goal': null,
        'profile_completed': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";

      if (e.code == 'email-already-in-use') {
        message = "Email already exists";
      } else if (e.code == 'weak-password') {
        message = "Password should be at least 6 characters";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Registration failed. Please try again.'};
    }
  }

  // ─── Sign Out ───
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // ─── Upload Profile Image (Local Storage) ───
  static Future<Map<String, dynamic>> uploadProfileImage() async {
    try {
      final user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) {
        return {'success': false, 'message': 'No image selected'};
      }

      // Get app's local documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String profileDir = '${appDir.path}/user_profiles';

      // Create directory if it doesn't exist
      await Directory(profileDir).create(recursive: true);

      // Delete any old profile images for this user
      final dir = Directory(profileDir);
      final List<FileSystemEntity> files = dir.listSync();
      for (var file in files) {
        if (file is File && file.path.contains(user.uid)) {
          await file.delete();
        }
      }

      // Use timestamp in filename to bust Flutter's image cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String localPath = '$profileDir/${user.uid}_$timestamp.jpg';
      final File localFile = await File(image.path).copy(localPath);

      // Store the local file path in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photo_url': localFile.path,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'photoUrl': localFile.path};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload image'};
    }
  }

  // ─── Helper: Check if photo_url is a local file path ───
  static bool isLocalFile(String path) {
    return path.isNotEmpty && !path.startsWith('http');
  }
}
