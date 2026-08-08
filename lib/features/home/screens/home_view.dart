import 'package:dapp/features/auth/providers/auth_provider.dart';
import 'package:dapp/features/cases/providers/case_provider.dart';
import 'package:dapp/features/cases/screens/create_case_page.dart';
import 'package:dapp/features/cases/screens/case_details_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CaseProvider>(context, listen: false).fetchCases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);
    final user = auth.user;
    final isSystemEmployee = user?.role.toLowerCase() == 'judge' || 
                             user?.role.toLowerCase() == 'lawyer' || 
                             user?.role.toLowerCase() == 'police';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      caseProvider.fetchCases();
                    },
                  )
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
                  child: caseProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : caseProvider.error != null
                          ? Center(child: Text(caseProvider.error!))
                          : caseProvider.cases.isEmpty
                              ? Center(
                                  child: Text(
                                    "No cases found.",
                                    style: GoogleFonts.inter(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: caseProvider.cases.length,
                                  itemBuilder: (context, index) {
                                    final caseItem = caseProvider.cases[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withOpacity(0.1),
                                          ),
                                        ),
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CaseDetailsPage(caseItem: caseItem),
                                            ),
                                          );
                                        },
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.gavel, color: Colors.blue[800]),
                                        ),
                                        title: Text(
                                          caseItem.title,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          'Case #${caseItem.caseNumber} • ${caseItem.status}',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: isSystemEmployee
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCasePage()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text("Create Case", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
