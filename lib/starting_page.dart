import 'package:dapp/navigationbar/navigation_page.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:reown_appkit/modal/appkit_modal_impl.dart';
import 'package:reown_appkit/reown_appkit.dart';

class StartingPage extends StatefulWidget {
  @override
  State<StartingPage> createState() => _MyStartingPageState();
}

class _MyStartingPageState extends State<StartingPage> {
  late ReownAppKitModal _appKitModal;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAppKit();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _appKitModal.removeListener(_handleConnectionChange);
    super.dispose();
  }

  void _handleConnectionChange(){
      if(_appKitModal.isConnected){
        _navigateToDashboard();
      }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => NavigationPage(_appKitModal),
      ),
    );
  }

  Future<void> _initializeAppKit() async {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'ff261773380c8b4378cba48bc91260aa',
        metadata: const PairingMetadata(
          name: 'DALRC',
          description: 'Decentralized Legal Document Storage',
          url: 'https://dalrc.com',
          icons: ['https://dalrc.com/logo.png'],
          redirect: Redirect(
            native: 'dalrc://',
            universal: 'https://dalrc.com/wallet',
            linkMode: true,
          ),
        ),
      );

      _appKitModal.addListener(_handleConnectionChange);

      await _appKitModal.init();

      setState((){
      _isLoading = false;
    });

      if(_appKitModal.isConnected){
        _navigateToDashboard();
      }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: ModelViewer(
                        src: 'assets/vault.glb',
                        backgroundColor: Colors.transparent,
                        autoRotate: true,
                        cameraControls: true,
                        shadowIntensity: 1,
                        ar: false,
                        loading: Loading.eager,

                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // App Title
                const Text(
                  'DALRC',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your Personalised e-Vault for Legal Documents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Connection Status
                if (_isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Initializing wallet connection...',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else if (_errorMessage != null)
                  Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _initializeAppKit,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: AppKitModalConnectButton(
                        appKit: _appKitModal,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Footer Text
                const Text(
                  'Secure • Immutable • Decentralized',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}