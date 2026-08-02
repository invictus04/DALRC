import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../../providers/auth_provider.dart';
import '../../navigationbar/home_page.dart';

class ConnectWalletPage extends StatefulWidget {
  const ConnectWalletPage({super.key});

  @override
  State<ConnectWalletPage> createState() => _ConnectWalletPageState();
}

class _ConnectWalletPageState extends State<ConnectWalletPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLinking = false;
  bool _isNavigating = false;
  ReownAppKitModal? _appKitModal;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.initAppKit(context);
    
    if (!mounted) return;
    
    _appKitModal = auth.appKitModal;
    _appKitModal?.addListener(_handleConnectionChange);

    setState(() {
      _isLoading = false;
    });

    if (auth.isAuthenticated && !auth.needsWalletConnection) {
      _navigateToDashboard();
      return;
    }

    if (_appKitModal?.isConnected == true) {
      _handleConnectionChange();
    }
  }

  @override
  void dispose() {
    _appKitModal?.removeListener(_handleConnectionChange);
    super.dispose();
  }

  void _handleConnectionChange() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.isAuthenticated && !auth.needsWalletConnection) {
      if (mounted) _navigateToDashboard();
      return;
    }

    if (_isLinking) return;

    if (_appKitModal?.isConnected == true) {
      _isLinking = true;
      final chainId = _appKitModal!.selectedChain?.chainId ?? '';
      final nameSpace = NamespaceUtils.getNamespaceFromChain(chainId);
      final address = _appKitModal!.session!.getAddress(nameSpace);

      if (address != null) {
        final success = await auth.linkWallet(address);
        if (success && mounted) {
          _navigateToDashboard();
        } else if (mounted) {
          setState(() {
            _errorMessage = auth.error ?? 'Failed to link wallet to your account.';
          });
        }
      }
      _isLinking = false;
    }
  }

  void _navigateToDashboard() {
    if (_isNavigating) return;
    _isNavigating = true;
    if (_appKitModal == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(_appKitModal!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Web3 Identity',
          style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minimalist Wallet Icon / Graphic
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 40),
                
                Text(
                  'Connect Wallet',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Link your crypto wallet to secure your digital identity and interact with decentralized legal records.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                if (_isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Initializing secure connection...',
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                    ],
                  )
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                            _initialize();
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                      appKit: _appKitModal!,
                    ),
                  ),
                  
                const SizedBox(height: 48),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'End-to-End Encrypted',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
