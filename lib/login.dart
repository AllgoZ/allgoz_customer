import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'package:allgoz/main.dart';
import 'package:allgoz/Home/home.dart';
import 'entername.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = "";
  bool _isOtpSent = false;
  final TextEditingController _otpController = TextEditingController();

  void _sendOtp() async {
    String phoneNumber = _mobileController.text.trim().replaceAll("+91 ", "");
    if (phoneNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid 10-digit phone number")),
      );
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: "+91$phoneNumber",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _checkUserExists();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Verification Failed: ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _verifyOtp() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);
      _checkUserExists();
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = "Invalid OTP. Please check the code and try again.";
          break;
        case 'session-expired':
          errorMessage = "OTP session expired. Please request a new OTP.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many requests. Please try again later.";
          break;
      // Add more cases as needed
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred. Please try again.")),
      );
    }
  }
  void _checkUserExists() async {
    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EnterNamePage()));
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
                SizedBox(height: 60),
                Center(
                  child: Text(
                    'AllGoZ',
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                Text(
                  'Explore Your Town',
                  style: TextStyle(fontSize: 40, fontFamily: 'Majalla', fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                SizedBox(height: 100),
                if (!_isOtpSent)
                  Column(
                    children: [
                      Container(
                        width: 312,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 9, offset: Offset(0, 4)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.all(12),
                            hintText: 'Enter Mobile Number',
                            hintStyle: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1C85EA).withOpacity(0.9),
                          minimumSize: Size(312, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          elevation: 5,
                        ),
                        child: Text('Get OTP', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                if (_isOtpSent)
                  Column(
                    children: [
                      Text("Enter OTP sent to your phone", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      Pinput(
                        controller: _otpController,
                        length: 6,
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 50,
                          textStyle: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(312, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          elevation: 5,
                        ),
                        child: Text('Verify OTP', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
