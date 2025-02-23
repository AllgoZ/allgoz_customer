import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _locationSharing = true;
  bool _personalizedAds = false;
  bool _dataCollection = true;

  void _toggleSetting(bool value, String setting) {
    setState(() {
      if (setting == 'Location Sharing') _locationSharing = value;
      if (setting == 'Personalized Ads') _personalizedAds = value;
      if (setting == 'Data Collection') _dataCollection = value;
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account deletion request submitted.')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Privacy Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingTile('Location Sharing', _locationSharing, (value) => _toggleSetting(value, 'Location Sharing')),
          Divider(),
          _buildSettingTile('Personalized Ads', _personalizedAds, (value) => _toggleSetting(value, 'Personalized Ads')),
          Divider(),
          _buildSettingTile('Data Collection', _dataCollection, (value) => _toggleSetting(value, 'Data Collection')),
          Divider(),

          SizedBox(height: 20),

          // 🚩 Delete Account Button
          ElevatedButton(
            onPressed: _showDeleteConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: Text('Delete Account', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Reusable Setting Tile
  Widget _buildSettingTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Switch(
        value: value,
        activeColor: Color(0xFF4A90E2),
        onChanged: onChanged,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PrivacySettingsScreen(),
  ));
}
