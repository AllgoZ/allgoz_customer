import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _generalNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalOffers = false;
  bool _deliveryUpdates = true;
  bool _newProductLaunches = false;

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification settings updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        title: Text('Notification Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchTile(
              title: 'Enable Notifications',
              subtitle: 'Turn on/off all app notifications',
              value: _generalNotifications,
              onChanged: (value) {
                setState(() {
                  _generalNotifications = value;
                  if (!value) {
                    _orderUpdates = false;
                    _promotionalOffers = false;
                    _deliveryUpdates = false;
                    _newProductLaunches = false;
                  }
                });
              },
            ),
            Divider(thickness: 1),

            // ✅ Specific Notification Toggles (Disabled when general notifications are off)
            _buildSwitchTile(
              title: 'Order Updates',
              subtitle: 'Get updates about your orders',
              value: _orderUpdates,
              onChanged: _generalNotifications
                  ? (value) => setState(() => _orderUpdates = value)
                  : null,
            ),
            _buildSwitchTile(
              title: 'Promotional Offers',
              subtitle: 'Receive exciting offers & discounts',
              value: _promotionalOffers,
              onChanged: _generalNotifications
                  ? (value) => setState(() => _promotionalOffers = value)
                  : null,
            ),
            _buildSwitchTile(
              title: 'Delivery Updates',
              subtitle: 'Get real-time delivery status',
              value: _deliveryUpdates,
              onChanged: _generalNotifications
                  ? (value) => setState(() => _deliveryUpdates = value)
                  : null,
            ),
            _buildSwitchTile(
              title: 'New Product Launches',
              subtitle: 'Stay updated with the latest products',
              value: _newProductLaunches,
              onChanged: _generalNotifications
                  ? (value) => setState(() => _newProductLaunches = value)
                  : null,
            ),

            Spacer(),

            // ✅ Save Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
              child: Text('Save Settings', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Reusable Switch Tile Widget
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: value,
      activeColor: Color(0xFF4A90E2),
      onChanged: onChanged,
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NotificationSettingsScreen(),
  ));
}
