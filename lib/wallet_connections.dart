import 'package:reown_appkit/reown_appkit.dart';
import 'package:flutter/material.dart';

class WalletScreenWithButtons extends StatefulWidget {
  const WalletScreenWithButtons({super.key});

  @override
  State<WalletScreenWithButtons> createState() => _WalletScreenWithButtonsState();
}

class _WalletScreenWithButtonsState extends State<WalletScreenWithButtons> {
  late ReownAppKitModal _appKitModal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAppKit();
  }

  Future<void> _initializeAppKit() async {
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: 'ff261773380c8b4378cba48bc91260aa',
      metadata: const PairingMetadata(
        name: 'Your App',
        description: 'Description',
        url: 'https://yourapp.com',
        icons: ['https://yourapp.com/logo.png'],
        redirect: Redirect(
          native: 'yourapp://',
          universal: 'https://yourapp.com/wallet',
          linkMode: true,
        ),
      ),
    );
    await _appKitModal.init();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MetaMask Connection'),
        actions: [
          AppKitModalConnectButton(appKit: _appKitModal,),
        ],),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppKitModalNetworkSelectButton(appKit: _appKitModal),
            AppKitModalConnectButton(appKit: _appKitModal),
            if (_appKitModal.isConnected)
              AppKitModalAccountButton(appKitModal: _appKitModal),
            Visibility(child: AppKitModalAddressButton(appKitModal: _appKitModal), visible: _appKitModal.isConnected,),

            // ElevatedButton(onPressed: (){
            //   _appKitModal.openModalView();
            // }, child: Text('data')),
            //
            // ElevatedButton(onPressed: (){
            //   _appKitModal.openModalView(ReownAppKitModalQRCodePage());
            // }, child: Text('data')),
            //
            // ElevatedButton(onPressed: (){
            //   _appKitModal.openModalView(ReownAppKitModalAllWalletsPage());
            // }, child: Text('data'))
          ],
        ),
      ),
    );
  }
}
