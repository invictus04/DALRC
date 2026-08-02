import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_page.dart';

class HomePage extends StatefulWidget {
  final ReownAppKitModal appKitModal;

  const HomePage(this.appKitModal, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Since AppKit is handled globally in AuthProvider, 
    // we don't strictly need to manage listeners here if we don't want to force navigation on disconnect,
    // but we can leave it for safety if needed. We'll skip it to avoid race conditions.
  }

  String _getAppBarTitle() {
    if (_currentIndex == 1) return 'My Profile';
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return 'DALRC Dashboard';

    switch (user.role.toLowerCase()) {
      case 'judge':
        return 'Welcome, Judge';
      case 'lawyer':
        return 'Lawyer Dashboard';
      case 'police':
        return 'Police Portal';
      case 'admin':
        return 'Admin Panel';
      default:
        return 'Civilian Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeView(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.blue.shade800,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const List<String> _indianCaseNames = [
    'State of Maharashtra vs. Suresh Kumar',
    'Ramesh & Co. vs. Delhi Development Authority',
    'Priya Sharma vs. Rahul Sharma (Divorce Petition)',
    'Sunil Properties vs. HDFC Bank',
    'XYZ Pharmaceuticals Pvt Ltd vs. Commissioner of Income Tax',
    'Ashok Leyland Employees Union vs. State of Tamil Nadu',
    'M/s Gupta Builders vs. RERA Tribunal',
    'Inspector of Police, CBI vs. Anjali Desai',
    'Venkateswara Rao vs. State of Andhra Pradesh',
    'Amitabh Bachchan Corp. vs. Reliance Big Entertainment',
  ];

  static const List<String> _caseDescriptions = [
    'Dispute over agricultural land measuring 5 acres in village Khanda, Haryana',
    'Case filed by bride\'s family alleging dowry demands and harassment',
    'Dispute among siblings over ancestral property in Delhi',
    'Allegations of fraudulent loan transactions worth ₹2.5 crores',
    'PIL seeking measures to reduce air pollution in Delhi NCR',
    'Mutual consent divorce petition with child custody issues',
    'Case regarding dishonor of cheque worth ₹15 lakhs',
    'Appeal against lower court judgment in murder case',
    'Complaint regarding defective construction of apartment',
    'Case involving concealment of income worth ₹50 lakhs',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/bank-locker.png',
                  height: 250,
                  width: 250,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome Back,",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Text(
              user != null ? "${user.firstName} ${user.lastName}" : "Here are your cases",
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Cases",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final caseName = _indianCaseNames[index % _indianCaseNames.length];
                    final caseDesc = _caseDescriptions[index % _caseDescriptions.length];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          caseName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        subtitle: Text(
                          caseDesc,
                          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.blue[800],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
