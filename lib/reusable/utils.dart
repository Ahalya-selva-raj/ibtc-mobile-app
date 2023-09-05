import 'dart:io';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static int num = 0;

  static Future<void> downloadPdfFiles(
      {required List<int> bytes, required String invoiceNumber}) async {
    String dir;
    if (Platform.isIOS) {
      dir = (await getApplicationDocumentsDirectory()).path;
    } else {
      var tempDir = await DownloadsPathProvider.downloadsDirectory;
      if (tempDir != null) {
        dir = tempDir.path;
      } else {
        dir = (await getExternalStorageDirectories(
            type: StorageDirectory.downloads))![0]
            .path;
      }
    }
    var fileName = '$dir/Invoice $invoiceNumber.pdf';
    await checkAndSavePdfFile(dir: dir, fileName: fileName,invoiceNumber: invoiceNumber, bytes: bytes);
  }

  static Future<void> checkAndSavePdfFile(
      {required String dir,
        required String fileName,
        required String invoiceNumber,
        required List<int> bytes}) async {
    bool fileExists = await File(fileName).exists();

    if (fileExists) {
      num++;
      fileName =  '$dir/Invoice $invoiceNumber${num == 0 ? "" : "-$num"}.pdf';
      await checkAndSavePdfFile(dir: dir, fileName: fileName, bytes: bytes, invoiceNumber: invoiceNumber);
    } else {
      try {
        File file = File(fileName);
        await file.writeAsBytes(bytes);
        // Assuming OpenFilex is a valid library for opening files.
        // Make sure you have imported and set up the necessary packages.
        // await sendEmailWithAttachment(fileName: "Invoice $invoiceNumber",path: file.path);
        OpenFilex.open(fileName);
      } catch (e) {
        debugPrint("Error: ${e.toString()}");
      }
    }
  }

  static sendEmailWithAttachment({fileName,path}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ahalyaraj2411@gmail.com',
      queryParameters: {
        'subject': fileName,
        'body': 'Hi,\n\nKindly check the attached file to download $fileName\n\n\n\nRegards,\nIBTC Trading & Contracting W.L.L.',
        'attachment': path,
      },
    );

    final String emailLaunchUriString = emailLaunchUri.toString();

    if (await canLaunchUrl(Uri.parse(emailLaunchUriString))) {
      await launchUrl(Uri.parse(emailLaunchUriString));
    } else {
      throw 'Could not launch $emailLaunchUriString';
    }
  }
}
