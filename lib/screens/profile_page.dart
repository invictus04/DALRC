import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../../providers/auth_provider.dart';
import '../../starting_page.dart';
import 'profile/update_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.appKitModal == null) {
        auth.initAppKit(context).then((_) {
          auth.appKitModal?.addListener(_onWalletConnectionChanged);
        });
      } else {
        auth.appKitModal?.addListener(_onWalletConnectionChanged);
      }
    });
  }

  @override
  void dispose() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.appKitModal?.removeListener(_onWalletConnectionChanged);
    super.dispose();
  }

  void _onWalletConnectionChanged() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final appKitModal = auth.appKitModal;
    if (appKitModal?.isConnected == true) {
      final chainId = appKitModal!.selectedChain?.chainId ?? '';
      final nameSpace = NamespaceUtils.getNamespaceFromChain(chainId);
      final address = appKitModal.session?.getAddress(nameSpace);
      
      if (address != null && address != auth.user?.walletAddress) {
         final success = await auth.linkWallet(address);
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(success ? 'Wallet updated successfully' : (auth.error ?? 'Failed to update wallet')),
               backgroundColor: success ? Colors.green : Colors.red,
             ),
           );
         }
      }
    }
  }

  Future<void> _logout() async {
    if (_isNavigating) return;
    _isNavigating = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              _isNavigating = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final appKitModal = auth.appKitModal;
              
              await auth.logout();

              if (appKitModal != null && appKitModal.isConnected) {
                await appKitModal.disconnect();
              }

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const StartingPage()),
                (Route<dynamic> route) => false,
              );

              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  Widget _buildProfileItem(IconData icon, String title, String value, {bool isVerified = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isVerified)
                      const Icon(Icons.verified, color: Colors.green, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  '${user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : ''}${user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${user.firstName} ${user.lastName}',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Profile Details
            _buildProfileItem(Icons.phone_outlined, 'Phone Number', user.phoneNumber, isVerified: user.isVerified),
            if (user.userId != null)
              _buildProfileItem(Icons.badge_outlined, 'User ID', user.userId!),
            if (user.employeeId != null)
              _buildProfileItem(Icons.badge_outlined, 'Employee ID', user.employeeId!),
            if (user.walletAddress != null)
              _buildProfileItem(Icons.account_balance_wallet_outlined, 'Wallet Address', 
                '${user.walletAddress!.substring(0, 6)}...${user.walletAddress!.substring(user.walletAddress!.length - 4)}',
                isVerified: true
              ),
            
            const SizedBox(height: 32),

            // Update Wallet Button
            if (auth.appKitModal != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AppKitModalConnectButton(
                  appKit: auth.appKitModal!,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Change Password Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
                  );
                },
                icon: const Icon(Icons.lock_reset),
                label: Text('Change Password', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                  side: BorderSide(color: Colors.blue.shade800),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text('Logout', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
