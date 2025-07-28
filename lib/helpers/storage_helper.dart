import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageHelper {
  StorageHelper._();

  static final StorageHelper instance = StorageHelper._();

  // Define the correct bucket URL here
  static const _bucket = 'gs://moh-aligo.firebasestorage.app';

  // Update the storage instance to use the correct bucket
  final _storage = FirebaseStorage.instanceFor(bucket: _bucket);

  Future<(String downloadUrl, String path)> uploadInventoryImage({
    required Uint8List data,
    required String code,
  }) async {
    try {
      // Use the custom storage instance
      final storageRef = _storage.ref().child(
          'inventory_images/$code-${DateTime.now().millisecondsSinceEpoch}.png');

      final task = await storageRef.putData(data);
      final url = await task.ref.getDownloadURL();
      return (url, storageRef.fullPath);
    } catch (e, stk) {
      print('unable to upload image: $e');
      print(stk);
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    try {
      // Use the custom storage instance
      await _storage.ref(path).delete();
    } catch (_) {
      /* ignore missing */
    }
  }
}
