import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //Uploads an incident photo to Firebase Storage and returns its download URL
  Future<String> uploadIncidentImage({
    required File imageFile,
    required String incidentId,
  }) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Selected image file does not exist on the device.');
      }

      final String fileName = '$incidentId.jpg';

      // Points to: incident_images/{incidentId}.jpg
      final Reference storageRef = _storage
          .ref()
          .child(AppConstants.storageFolder)
          .child(fileName);

      // Sets MIME type so the browser and Flutter Image.network render it as a JPEG
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Storage upload failed (${e.code}): ${e.message}');
    } catch (e) {
      final String message = e.toString().replaceFirst('Exception: ', '');
      throw Exception('Image upload error: $message');
    }
  }

  // Deletes an incident photo from Firebase Storage using its download URL
  Future<void> deleteIncidentImage(String imageUrl) async {
    try {
      if (imageUrl.trim().isEmpty) {
        return;
      }
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete image (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Delete image error: ${e.toString()}');
    }
  }
}