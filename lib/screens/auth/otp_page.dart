import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'login_page.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;

  const OtpPage({super.key, required this.phoneNumber});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  String _otp = '';

  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyOtp(
      phoneNumber: widget.phoneNumber,
      otp: _otp,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Verified successfully! Please login.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => route.isFirst,
        );
      }
    } else {
      if (mounted && auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _resendOtp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resendOtp(phoneNumber: widget.phoneNumber);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully!'), backgroundColor: Colors.green),
        );
      } else if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Verification',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit OTP sent to\n${widget.phoneNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // OTP Input
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter OTP';
                      if (val.trim().length != 6) return 'OTP must be 6 digits';
                      return null;
                    },
                    onSaved: (val) => _otp = val!.trim(),
                  ),
                  const SizedBox(height: 32),

                  // Verify Button
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Verify OTP', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),

                  // Resend OTP Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Didn\'t receive the code? ', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                      GestureDetector(
                        onTap: auth.isLoading ? null : _resendOtp,
                        child: Text(
                          'Resend',
                          style: GoogleFonts.inter(
                            color: auth.isLoading ? Colors.grey : Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
