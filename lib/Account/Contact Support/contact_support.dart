import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatefulWidget {
  @override
  _ContactSupportScreenState createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'allgozintown@gmail.com',
        query: Uri.encodeFull(
          'subject=${_subjectController.text}'
              '&body=Name: ${_nameController.text}\n'
              'Email: ${_emailController.text}\n\n'
              'Product Request: ${_productController.text}\n\n'
              '${_messageController.text}',
          ),
        );

      _launchEmail(emailLaunchUri);
    }
  }

  void _launchEmail(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final scaleFactor = screenWidth / 390;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text(
          'Contact Support',
          style: TextStyle(fontSize: 20 * scaleFactor,color: Colors.white,fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📞 Support Info
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scaleFactor)),
                child: ListTile(
                  leading: Icon(
                      Icons.email, color: Colors.blue, size: 24 * scaleFactor),
                  title: Text(
                    'allgozintown@gmail.com',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 16 * scaleFactor),
                  ),
                  subtitle: Text('Email Us Anytime',
                      style: TextStyle(fontSize: 14 * scaleFactor)),
                ),
              ),
              SizedBox(height: 10 * scaleFactor),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scaleFactor)),
                child: ListTile(
                  leading: Icon(
                      Icons.phone, color: Colors.green, size: 24 * scaleFactor),
                  title: Text(
                    '+91 9500381132',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 16 * scaleFactor),
                  ),
                  subtitle: Text('Call Us (9 AM - 6 PM)',
                      style: TextStyle(fontSize: 14 * scaleFactor)),
                ),
              ),
              SizedBox(height: 20 * scaleFactor),

              // 📋 Contact Form
              Text(
                'Send Us a Message',
                style: TextStyle(
                    fontSize: 18 * scaleFactor, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10 * scaleFactor),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Your Name', _nameController, scaleFactor),
                    _buildTextField(
                        'Email Address', _emailController, scaleFactor,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField('Subject', _subjectController, scaleFactor),
                    _buildTextField('Request Product', _productController, scaleFactor),
                    _buildTextField('Message', _messageController, scaleFactor,
                        maxLines: 4),
                    SizedBox(height: 20 * scaleFactor),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(double.infinity, 50 * scaleFactor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  9 * scaleFactor)),
                        ),
                        child: Text(
                          'Send Message',
                          style: TextStyle(fontSize: 18 * scaleFactor,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20 * scaleFactor),

              // 💬 Live Chat (Optional)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Live Chat feature coming soon!')),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline, size: 20 * scaleFactor),
                  label: Text('Start Live Chat',
                      style: TextStyle(fontSize: 16 * scaleFactor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    minimumSize: Size(double.infinity, 50 * scaleFactor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9 * scaleFactor)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller,
      double scaleFactor,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0 * scaleFactor),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        style: TextStyle(fontSize: 16 * scaleFactor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14 * scaleFactor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8 * scaleFactor),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 12 * scaleFactor, vertical: 10 * scaleFactor),
        ),
      ),
    );
  }
}
  void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ContactSupportScreen(),
  ));
}
