import 'package:flutter/material.dart';
import 'package:allgoz/main.dart'; // Ensure the correct path to main.dart

class LoginPage extends StatelessWidget {
  final TextEditingController _mobileController = TextEditingController();

  LoginPage({super.key});

  void _navigateToEnterName(BuildContext context) {
    if (_mobileController.text.isNotEmpty) {
      Navigator.pushNamed(context, '/entername');
    }
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms and Conditions'),
        content: Text(' Developer : Nagul , Marketing : Giri, Designer : Naveen , We are working on a app for our town people to connect search buy sell products, '),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent background from moving
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundWidget(), // Add the background here
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                Center(
                  child: Text(
                    'AllGoZ',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Text(
                  'Explore Your Town',
                  style: TextStyle(
                    fontSize: 40,
                    fontFamily: 'Majalla',
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 100),
                GestureDetector(
                  onTap: () => _showTermsAndConditions(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'By Signing in you are agreeing our ',
                      style: TextStyle(
                        fontSize: 19,
                        fontFamily: 'Majalla',
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,

                      ),
                      children: [
                        TextSpan(
                          text: 'Team',
                          style: TextStyle(
                            color: Color(0xFF1C85EA),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' and ',
                          style: TextStyle(color: Colors.grey,fontWeight: FontWeight.bold,),

                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFF1C85EA),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 37),
                Container(
                  width: 312,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.9), // Slight transparency
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 9,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(10),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Thanglish',
                        child: Text('Thanglish', style: TextStyle(fontFamily: 'Majalla', fontSize: 22, color: Colors.black,
                          fontWeight: FontWeight.bold,)),
                      ),
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English', style: TextStyle(fontFamily: 'Majalla' ,fontSize: 22, color: Colors.black,
                          fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: 'Tamil',
                        child: Text('தமிழ்', style: TextStyle(fontFamily: 'NotoSans' ,fontSize: 16, color: Colors.black87,
                          fontWeight: FontWeight.bold,)),
                      ),
                    ],
                    onChanged: (value) {},
                    hint: Text('Choose the Language', style: TextStyle(fontFamily: 'Majalla')),
                    style: TextStyle(fontFamily: 'Majalla', fontSize: 20, color: Colors.white,),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(height: 50),
                Container(
                  width: 312,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 9,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    onTap: () {
                      if (_mobileController.text.isEmpty) {
                        _mobileController.text = '+91 ';
                        _mobileController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _mobileController.text.length),
                        );
                      }
                    },
                    onChanged: (value) {
                      if (!value.startsWith('+91 ')) {
                        _mobileController.text = '+91 ';
                        _mobileController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _mobileController.text.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(12),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'Mobile Number',
                      hintStyle: TextStyle(
                        fontFamily: 'Majalla',
                        fontSize: 22,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Majalla',
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _navigateToEnterName(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C85EA).withOpacity(0.9),
                    minimumSize: Size(312, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    elevation: 5,
                  ),
                  child: Text('Continue', style: TextStyle(fontFamily: 'Majalla', fontSize: 30, color: Colors.white,fontWeight: FontWeight.bold,)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
