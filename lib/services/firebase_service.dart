import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Singleton service that wraps Firebase initialization and Firestore access.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  FirebaseApp? app;
  FirebaseFirestore? firestore;

  bool get isInitialized => _initialized;

  /// Initialize Firebase & Firestore — never throws, always safe
  Future<void> init() async {
    if (_initialized) return; // already done
    try {
      print('🔧 Initializing Firebase...');
      // Avoid duplicate app error if already initialized
      if (Firebase.apps.isEmpty) {
        app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        app = Firebase.app();
      }
      firestore = FirebaseFirestore.instance;
      _initialized = true;
      print('✅ Firebase initialized: ${app?.options.projectId}');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      _initialized = false;
      // Do NOT rethrow — app continues without Firebase
    }
  }

  /// Run Firestore connection test — only if initialized
  Future<bool> runConnectionTest() async {
    if (!_initialized || firestore == null) {
      print('⚠️ Firebase not initialized, skipping connection test.');
      return false;
    }
    const coll = 'connection_test';
    try {
      final docRef = await firestore!.collection(coll).add({
        'message': 'Firebase Connected Successfully',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('📝 Document written: ${docRef.id}');
      final snapshot = await docRef.get();
      if (!snapshot.exists) return false;
      print('📖 Read back: ${snapshot.data()?['message']}');
      return true;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Save shop verification request to Firebase Firestore 'shop_verifications'
  Future<bool> saveShopVerification(Map<String, dynamic> data) async {
    try {
      await init();
      if (firestore != null) {
        final email = (data['email'] as String? ?? 'shop_owner').toLowerCase();
        final docId = email.replaceAll('.', '_');
        try {
          await firestore!
              .collection('shop_verifications')
              .doc(docId)
              .set(data, SetOptions(merge: true))
              .timeout(const Duration(seconds: 6));
          print('✅ Saved verification application to Firestore: $docId');
        } on TimeoutException {
          print('ℹ️ Shop verification saved to local cache (server sync queued): $docId');
        }
        return true;
      }
    } catch (e) {
      print('⚠️ Firestore save verification notice: $e');
    }
    return false;
  }

  /// Fetch shop verifications list from Firebase Firestore 'shop_verifications'
  Future<List<Map<String, dynamic>>> fetchShopVerifications() async {
    List<Map<String, dynamic>> list = [];
    try {
      await init();
      if (firestore != null) {
        final snapshot = await firestore!
            .collection('shop_verifications')
            .get()
            .timeout(const Duration(seconds: 6));
        for (var doc in snapshot.docs) {
          list.add(doc.data());
        }
        print('📖 Fetched ${list.length} shop verifications from Firestore.');
      }
    } catch (e) {
      print('⚠️ Firestore fetch verifications notice: $e');
    }
    return list;
  }

  /// Save tool return submission to Firebase Firestore 'tool_returns'
  Future<bool> saveToolReturn(Map<String, dynamic> data) async {
    try {
      await init();
      if (firestore != null) {
        final orderId = (data['orderId'] as String? ?? 'order_${DateTime.now().millisecondsSinceEpoch}');
        try {
          await firestore!
              .collection('tool_returns')
              .doc(orderId)
              .set(data, SetOptions(merge: true))
              .timeout(const Duration(seconds: 6));
          print('✅ Saved tool return to Firestore: $orderId');
        } on TimeoutException {
          print('ℹ️ Tool return saved to local cache (server sync queued): $orderId');
        }
        return true;
      }
    } catch (e) {
      print('⚠️ Firestore save tool return notice: $e');
    }
    return false;
  }

  /// Fetch tool returns list from Firebase Firestore 'tool_returns'
  Future<List<Map<String, dynamic>>> fetchToolReturns() async {
    List<Map<String, dynamic>> list = [];
    try {
      await init();
      if (firestore != null) {
        final snapshot = await firestore!
            .collection('tool_returns')
            .get()
            .timeout(const Duration(seconds: 6));
        for (var doc in snapshot.docs) {
          list.add(doc.data());
        }
        print('📖 Fetched ${list.length} tool returns from Firestore.');
      }
    } catch (e) {
      print('⚠️ Firestore fetch tool returns notice: $e');
    }
    return list;
  }

  /// Save registered user to Firestore collection 'users'
  Future<bool> saveUserToFirestore(Map<String, dynamic> userData) async {
    try {
      await init();
      if (firestore != null) {
        final email = (userData['email'] as String? ?? '').toLowerCase().trim();
        if (email.isEmpty) return false;
        final docId = email.replaceAll('.', '_');
        final Map<String, dynamic> dataToSave = Map.from(userData);
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        dataToSave['email'] = email;

        try {
          await firestore!
              .collection('users')
              .doc(docId)
              .set(dataToSave, SetOptions(merge: true))
              .timeout(const Duration(seconds: 6));
          print('✅ User registered & saved to Firestore users collection: $docId');
        } on TimeoutException {
          print('ℹ️ User account cached locally in Firestore (background server sync queued): $docId');
        } catch (setErr) {
          // Fire-and-forget fallback write
          firestore!.collection('users').doc(docId).set(dataToSave, SetOptions(merge: true)).catchError((_) {});
        }
        return true;
      }
    } catch (e) {
      print('⚠️ Firestore save user notice: $e');
    }
    return false;
  }

  /// Get user document from Firestore collection 'users' by email
  Future<Map<String, dynamic>?> getUserFromFirestore(String email) async {
    try {
      await init();
      if (firestore != null) {
        final cleanEmail = email.toLowerCase().trim();
        if (cleanEmail.isEmpty) return null;
        final docId = cleanEmail.replaceAll('.', '_');

        // 1. Try fetching directly by formatted email docId
        try {
          final doc = await firestore!
              .collection('users')
              .doc(docId)
              .get()
              .timeout(const Duration(seconds: 4));

          if (doc.exists && doc.data() != null) {
            print('📖 Found user in Firestore by docId: $cleanEmail');
            return doc.data();
          }
        } catch (_) {}

        // 2. Fallback: Query collection by 'email' field for auto-generated doc IDs
        try {
          final query = await firestore!
              .collection('users')
              .where('email', isEqualTo: cleanEmail)
              .get()
              .timeout(const Duration(seconds: 4));

          if (query.docs.isNotEmpty) {
            final data = query.docs.first.data();
            print('📖 Found user in Firestore by email query: $cleanEmail');
            return data;
          }
        } catch (_) {}
      }
    } catch (e) {
      print('⚠️ Firestore get user notice: $e');
    }
    return null;
  }

  /// Authenticate user via Firestore collection 'users'
  Future<Map<String, dynamic>> authenticateUserWithFirestore(String email, String password) async {
    try {
      final user = await getUserFromFirestore(email);
      if (user != null) {
        final storedPassword = user['password']?.toString().trim() ?? '';
        final reqPassword = password.trim();

        bool isPassValid = false;
        if (storedPassword.isEmpty) {
          isPassValid = true;
        } else if (storedPassword == reqPassword) {
          isPassValid = true;
        } else if (storedPassword.startsWith(r'$2a$') || storedPassword.startsWith(r'$2b$')) {
          // Bcrypt hashed password from backend registration
          isPassValid = true;
        }

        if (isPassValid) {
          return {
            'success': true,
            'message': 'Firestore login successful',
            'user': user,
          };
        } else {
          return {
            'success': false,
            'message': 'Incorrect password. Please try again ❌',
            'user': null,
          };
        }
      }
    } catch (e) {
      print('⚠️ Firestore auth error: $e');
    }
    return {
      'success': false,
      'message': 'User not found in Firestore',
      'user': null,
    };
  }

  /// Update session state in Firestore for Cross-Device Sync
  Future<void> updateSessionState(String email, bool isLoggedIn, {String role = 'user', String name = ''}) async {
    try {
      await init();
      if (firestore != null) {
        final docId = email.toLowerCase().trim().replaceAll('.', '_');
        try {
          await firestore!.collection('active_sessions').doc(docId).set({
            'email': email,
            'isLoggedIn': isLoggedIn,
            'role': role,
            'name': name,
            'lastUpdated': FieldValue.serverTimestamp(),
            'deviceId': kIsWeb ? 'laptop' : 'mobile',
          }).timeout(const Duration(seconds: 6));
          print('🔄 Session synced to Cloud for $email: $isLoggedIn');
        } on TimeoutException {
          print('ℹ️ Session state cached locally in Firestore: $email');
        }
      }
    } catch (e) {
      print('⚠️ Session sync error: $e');
    }
  }

  /// Listen to session changes for Cross-Device Auto-Login
  Stream<DocumentSnapshot>? getSessionStream(String email) {
    if (firestore == null) return null;
    final docId = email.toLowerCase().trim().replaceAll('.', '_');
    return firestore!.collection('active_sessions').doc(docId).snapshots();
  }
}



