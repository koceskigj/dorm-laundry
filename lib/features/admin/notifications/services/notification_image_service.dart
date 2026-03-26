import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class NotificationImageService {
  final FirebaseStorage storage;
  final ImagePicker picker;

  NotificationImageService({
    required this.storage,
    ImagePicker? picker,
  }) : picker = picker ?? ImagePicker();

  Future<XFile?> pickFromCamera() async {
    return picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
  }

  Future<String> uploadNotificationImage({
    required XFile file,
    required String adminUid,
  }) async {
    final ext = file.name.contains('.')
        ? file.name.split('.').last
        : 'jpg';

    final ref = storage.ref().child(
      'notification_images/$adminUid/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );

    await ref.putFile(File(file.path));
    return ref.getDownloadURL();
  }
}