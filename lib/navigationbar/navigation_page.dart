import 'package:dapp/navigationbar/about_case_page.dart';
import 'package:dapp/navigationbar/home_page.dart';
import 'package:dapp/navigationbar/logs_page.dart';
import 'package:dapp/navigationbar/members_page.dart';
import 'package:dapp/navigationbar/verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';

class NavigationPage extends StatefulWidget {
  final ReownAppKitModal appKitModal;

  const NavigationPage(this.appKitModal, {super.key});

  @override
  State<StatefulWidget> createState() => _NavigationPage();
}

class _NavigationPage extends State<NavigationPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pages = [
      HomePage(),
      AboutCasePage(),
      MembersPage(),
      VerifyPage(),
      LogsPage(appKitModal: widget.appKitModal),
    ];
  }

  String _formatAddress(String address) {
    if (address.length < 26) return 'Invalid Address';
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  Widget ShowAddress() {
    final chainId = widget.appKitModal.selectedChain?.chainId ?? '';
    final nameSpace = NamespaceUtils.getNamespaceFromChain(chainId);
    final address = widget.appKitModal.session!.getAddress(nameSpace);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: address.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address is Copied to ClipBoard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Tooltip(
        message: address,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 100.0),
          child: Text(
            _formatAddress(address.toString()),
            maxLines: 1,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DALRC',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 2.0,
          ),
        ),
        actions: [ShowAddress()],
        surfaceTintColor: Colors.blue.shade600,
        actionsPadding: EdgeInsets.only(right: 10.0),
        forceMaterialTransparency: false,
        primary: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade700,

        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _navigatorKey.currentState!.push(
              MaterialPageRoute(builder: (context) => _pages[index]),
            );
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About Case'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'Verify Docs',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
        ],
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => _pages[_currentIndex],
            );
          },
        ),
      ),
    );
  }
}
