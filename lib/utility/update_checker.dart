import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('version_info')
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final latestVersion = data?['latest_version']?.toString().trim() ?? '';
      final updateRequired = data?['update_required'] ?? false;
      final changelog = data?['changelog'] ?? '';
      final playStoreUrl = data?['playstore_url'] ?? '';

      // Show popup only when update is required and version is different
      if (updateRequired && latestVersion != currentVersion) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: EdgeInsets.zero,
            title: Column(
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assets/icons/5.png',
                  height: 70,
                ),
                const SizedBox(height: 12),
                Text(
                  'New Update Available!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're using version $currentVersion."),
                const SizedBox(height: 8),
                Text(
                  "What's New:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(changelog),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
                    await launchUrl(
                      Uri.parse(playStoreUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                child: const Text(
                  "Update Now",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                },
                child: const Text(
                  "Update Later",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("❌ Update check failed: $e");
    }
  }
}
