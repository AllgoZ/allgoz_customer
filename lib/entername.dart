import 'package:flutter/material.dart';
import 'package:allgoz/main.dart';

class EnterNamePage extends StatefulWidget {
  const EnterNamePage({super.key});

  @override
  _EnterNamePageState createState() => _EnterNamePageState();
}

class _EnterNamePageState extends State<EnterNamePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _showReferralInput = false;

  void _submitName(BuildContext context) {
    if (_nameController.text.isNotEmpty) {
      Navigator.pushNamed(context, '/Home/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundWidget(),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'Ready to Explore Your Town ?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Majalla',
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: 50),
                Container(
                  width: 312,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'Enter Your Name',
                      hintStyle: TextStyle(fontFamily: 'Majalla', fontSize: 23, color: Colors.grey),
                    ),
                    style: TextStyle(
                      fontFamily: 'Majalla',
                      fontSize: 23,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReferralInput = true;
                    });
                  },
                  child: Text(
                    'Have a Referral Code?',
                    style: TextStyle(
                      fontFamily: 'Majalla',
                      fontSize: 21,
                      color: Color(0xFF1C85EA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_showReferralInput)
                  Container(
                    width: 312,
                    height: 47,
                    margin: EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _referralController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Enter Referral Code',
                        hintStyle: TextStyle(
                          fontFamily: 'Majalla',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.grey,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'Majalla',
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _submitName(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C85EA).withOpacity(0.9),
                    minimumSize: Size(312, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: Colors.black.withOpacity(0.3),
                    elevation: 10,
                  ),
                  child: Text(
                    'Explore',
                    style: TextStyle(
                      fontFamily: 'Majalla',
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
