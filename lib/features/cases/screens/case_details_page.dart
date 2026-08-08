import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dapp/features/search/models/search_user_model.dart';
import 'package:dapp/features/cases/models/case_model.dart';
import 'package:dapp/features/cases/models/case_details_model.dart';
import 'package:dapp/features/auth/models/user_model.dart';
import 'package:dapp/features/cases/providers/case_provider.dart';
import 'package:dapp/features/auth/providers/auth_provider.dart';
import 'package:dapp/features/cases/providers/case_doc_provider.dart';
import 'package:dapp/features/cases/widgets/upload_case_doc_dialog.dart';

import 'package:dapp/features/cases/widgets/case_doc_options_sheet.dart';

class CaseDetailsPage extends StatefulWidget {
  final CaseModel caseItem;

  const CaseDetailsPage({super.key, required this.caseItem});

  @override
  State<CaseDetailsPage> createState() => _CaseDetailsPageState();
}

class _CaseDetailsPageState extends State<CaseDetailsPage> with SingleTickerProviderStateMixin {
  late CaseModel _currentCase;
  CaseDetailsModel? _caseDetails;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentCase = widget.caseItem;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<CaseDocProvider>(context, listen: false).fetchCaseDocs(_currentCase.id);
      
      // Fetch latest case details
      final provider = Provider.of<CaseProvider>(context, listen: false);
      final latestCase = await provider.fetchCaseDetails(_currentCase.id);
      if (latestCase != null && mounted) {
        setState(() {
          _caseDetails = latestCase;
          _currentCase = latestCase.caseData;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCaseLocally() async {
    final provider = Provider.of<CaseProvider>(context, listen: false);
    final latestCase = await provider.fetchCaseDetails(_currentCase.id);
    if (latestCase != null && mounted) {
      setState(() {
        _caseDetails = latestCase;
        _currentCase = latestCase.caseData;
      });
    } else {
      final updatedCase = provider.cases.firstWhere(
        (c) => c.id == _currentCase.id,
        orElse: () => _currentCase,
      );
      if (mounted) {
        setState(() {
          _currentCase = updatedCase;
        });
      }
    }
  }

  Future<void> _showAddParticipantDialog() async {
    final searchController = TextEditingController();
    List<SearchUserModel> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Participant', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by Name, Email or Phone',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            if (searchController.text.isEmpty) return;
                            setState(() => isSearching = true);
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final results = await authProvider.searchUsers(searchController.text.trim());
                            setState(() {
                              searchResults = results;
                              isSearching = false;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSearching)
                      const Center(child: CircularProgressIndicator())
                    else if (searchResults.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            final wallet = user.walletAddress ?? 'No Wallet';
                            return ListTile(
                              title: Text(user.fullName),
                              subtitle: Text(wallet, style: const TextStyle(fontSize: 12)),
                              trailing: ElevatedButton(
                                onPressed: wallet == 'No Wallet' ? null : () {
                                  Navigator.pop(context);
                                  _showPermissionsDialog(user);
                                },
                                child: const Text('Add'),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Text('No users found.')
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPermissionsDialog(SearchUserModel user) async {
    bool canView = true;
    bool canUpload = false;
    bool isGranting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Configure Permissions', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User: ${user.fullName}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text('Role: ${user.role}', style: GoogleFonts.inter(color: Colors.grey)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Can View Case'),
                    value: canView,
                    onChanged: (val) => setState(() => canView = val),
                  ),
                  SwitchListTile(
                    title: const Text('Can Upload Documents'),
                    value: canUpload,
                    onChanged: (val) => setState(() => canUpload = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isGranting ? null : () async {
                    setState(() => isGranting = true);
                    final provider = Provider.of<CaseProvider>(context, listen: false);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    
                    final success = await provider.grantAccess(
                      _currentCase.id, 
                      user.walletAddress!, 
                      user.role, 
                      canView, 
                      canUpload
                    );
                    
                    if (mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(success ? 'Access granted!' : 'Failed to grant access'))
                      );
                      if (success) _refreshCaseLocally();
                    }
                  },
                  child: isGranting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Grant Access'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMigrateAdminDialog() async {
    final searchController = TextEditingController();
    List<SearchUserModel> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Migrate Case Admin', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Warning: You will lose administrative control of this case.',
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search System Employee (Judge/Lawyer/Police)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            if (searchController.text.isEmpty) return;
                            setState(() => isSearching = true);
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final results = await authProvider.searchUsers(searchController.text.trim());
                            setState(() {
                              searchResults = results.where((u) => 
                                u.role.toLowerCase() == 'judge' || 
                                u.role.toLowerCase() == 'lawyer' || 
                                u.role.toLowerCase() == 'police'
                              ).toList();
                              isSearching = false;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSearching)
                      const Center(child: CircularProgressIndicator())
                    else if (searchResults.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            final wallet = user.walletAddress ?? 'No Wallet';
                            return ListTile(
                              title: Text(user.fullName),
                              subtitle: Text('${user.role} • $wallet', style: const TextStyle(fontSize: 12)),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                                onPressed: wallet == 'No Wallet' ? null : () async {
                                  final provider = Provider.of<CaseProvider>(context, listen: false);
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  
                                  final success = await provider.migrateAdmin(_currentCase.id, wallet, user.role);
                                  
                                  if (mounted) {
                                    navigator.pop(); // Close dialog
                                    navigator.pop(); // Go back to Home
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text(success ? 'Admin migrated successfully!' : 'Migration failed'))
                                    );
                                  }
                                },
                                child: const Text('Transfer'),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Text('No valid system employees found.')
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab(bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentCase.status == 'active' ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentCase.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _currentCase.status == 'active' ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Admin: ${_currentCase.adminWallet}',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_currentCase.title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Case #${_currentCase.caseNumber} • ${_currentCase.courtName}', style: GoogleFonts.inter(color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text(_currentCase.description, style: GoogleFonts.inter(color: Colors.grey.shade700, height: 1.5)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Participants (${_currentCase.participants.length})', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              if (isAdmin)
                TextButton.icon(
                  onPressed: _showAddParticipantDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                )
            ],
          ),
          const SizedBox(height: 8),
          
          _currentCase.participants.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('No participants added yet.', style: GoogleFonts.inter(color: Colors.grey))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currentCase.participants.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = _currentCase.participants[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.person, color: Colors.blue.shade700),
                        ),
                        title: Text(p.wallet, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Role: ${p.role.toUpperCase()} • View: ${p.canView} • Upload: ${p.canUpload}', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: isAdmin 
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () async {
                                final provider = Provider.of<CaseProvider>(context, listen: false);
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                
                                final success = await provider.revokeAccess(_currentCase.id, p.wallet);
                                if (success) {
                                  _refreshCaseLocally();
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Access revoked')));
                                  }
                                }
                              },
                            )
                          : null,
                      ),
                    );
                  },
                ),
          
          const SizedBox(height: 32),
          
          if (isAdmin) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text('Advanced Settings', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showMigrateAdminDialog,
                icon: const Icon(Icons.swap_horiz, color: Colors.red),
                label: Text('Migrate Admin Control', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            ),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Consumer<CaseDocProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }
        if (provider.documents.isEmpty) {
          return Center(
            child: Text('No documents uploaded for this case.', style: GoogleFonts.inter(color: Colors.grey)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchCaseDocs(_currentCase.id),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = provider.documents[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description, color: Colors.blue.shade700),
                  ),
                  title: Text(doc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${(doc.fileSize / 1024).toStringAsFixed(2)} KB • Uploader: ${doc.uploadedBy}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CaseDocOptionsSheet(
                        parentContext: context,
                        caseItem: _currentCase, 
                        document: doc,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userWallet = auth.user?.walletAddress ?? '';
    
    final isAdmin = _caseDetails?.permissions.isUserCaseAdmin ?? (_currentCase.adminWallet.toLowerCase() == userWallet.toLowerCase());
    
    // Check if user has upload permission
    bool canUpload = _caseDetails?.permissions.hasUserUploadAccess ?? isAdmin;
    if (!isAdmin && _caseDetails == null) {
      final participant = _currentCase.participants.where((p) => p.wallet.toLowerCase() == userWallet.toLowerCase()).firstOrNull;
      if (participant != null && participant.canUpload) {
        canUpload = true;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Case Workspace', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade800,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade800,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isAdmin),
          _buildDocumentsTab(),
        ],
      ),
      floatingActionButton: (_tabController.index == 1 && canUpload) 
          ? FloatingActionButton.extended(
              heroTag: 'case_details_fab',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => UploadCaseDocDialog(caseItem: _currentCase),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: Text("Upload Doc", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
