import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Handles image selection and upload to Firebase Storage (or in-memory Demo cache).
class StorageService {
  StorageService({
    required this.isDemoMode,
    ImagePicker? imagePicker,
  }) : _picker = imagePicker ?? ImagePicker();

  final bool isDemoMode;
  final ImagePicker _picker;

  static final Map<String, Uint8List> _demoMemoryImages = <String, Uint8List>{};

  static Uint8List? getDemoImageBytes(String url) => _demoMemoryImages[url];

  Future<String?> pickAndUploadStallImage({
    required ImageSource source,
    required String vendorId,
    required String stallId,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1440,
      imageQuality: 82,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (isDemoMode) {
      final memoryKey = 'memory://stalls/$stallId/$fileName';
      _demoMemoryImages[memoryKey] = bytes;
      return memoryKey;
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('stalls')
        .child(vendorId)
        .child(stallId.isEmpty ? 'draft' : stallId)
        .child(fileName);

    final snapshot = await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }
}
