import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class DriveUploaderService {
  // Nama file kunci JSON Anda
  final String _credentialsFile = "UploaderDriveAPI.json";

  // Fungsi untuk mendapatkan kredensial dan membuat klien HTTP terotentikasi
  Future<AuthClient> _getAuthenticatedClient() async {
    final credentialsJson = await rootBundle.loadString(_credentialsFile);
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    const scopes = [drive.DriveApi.driveFileScope];

    return await clientViaServiceAccount(credentials, scopes);
  }

  // Fungsi utama untuk mengunggah file
  Future<String?> uploadFile(File file, String folderId) async {
    try {
      final client = await _getAuthenticatedClient();
      final driveApi = drive.DriveApi(client);

      // Metadata file di Google Drive
      final drive.File fileMetadata = drive.File()
        ..name = 'bukti_${DateTime.now().toIso8601String()}.jpg' // Nama file di Drive
        ..parents = [folderId]; // ID folder tujuan

      // Proses upload
      final response = await driveApi.files.create(
        fileMetadata,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      print("File ID: ${response.id}");
      // Anda bisa menyimpan ID file atau membuat link publik jika diperlukan
      return response.id; // Mengembalikan ID file yang baru diupload
    } catch (e) {
      print("Error uploading to Google Drive: $e");
      return null;
    }
  }
}