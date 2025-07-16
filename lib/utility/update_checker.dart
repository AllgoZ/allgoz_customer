import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('version_info')
          .get();

      if (!doc.exists) return;

      final latestVersion = doc['latest_version'] ?? "";
      final isRequired = doc['update_required'] ?? false;
      final changelog = doc['changelog'] ?? "";
      final playstoreUrl = doc['playstore_url'] ?? "";

      if (_isNewVersion(currentVersion, latestVersion)) {
        _showCupertinoUpdateDialog(context, latestVersion, changelog, playstoreUrl, isRequired);
      }
    } catch (e) {
      print("Update check failed: $e");
    }
  }

  static bool _isNewVersion(String current, String latest) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> l = latest.split('.').map(int.parse).toList();
    for (int i = 0; i < l.length; i++) {
      if (i >= c.length || l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static void _showCupertinoUpdateDialog(BuildContext context, String version, String changelog, String url, bool isRequired) {
    showCupertinoDialog(
      barrierDismissible: !isRequired,
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Update Available"),
          content: Column(
            children: [
              SizedBox(height: 10),
              Text("Please update to version $version to continue."),
              SizedBox(height: 10),
              Text("What's new:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(changelog, style: TextStyle(fontSize: 13)),
            ],
          ),
          actions: <Widget>[
            if (!isRequired)
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text("Later"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text("Update"),
              onPressed: () {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        );
      },
    );
  }
}
