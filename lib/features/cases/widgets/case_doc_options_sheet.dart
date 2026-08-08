import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dapp/features/cases/models/case_model.dart';
import 'package:dapp/features/cases/models/case_doc_model.dart';
import 'package:dapp/features/auth/models/user_model.dart';
import 'package:dapp/features/cases/models/audit_log_model.dart';
import 'package:dapp/features/cases/providers/case_doc_provider.dart';
import 'package:dapp/features/auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class CaseDocOptionsSheet extends StatelessWidget {
  final CaseModel caseItem;
  final CaseDocModel document;

  const CaseDocOptionsSheet({super.key, required this.caseItem, required this.document});

  Future<void> _viewDocument(BuildContext context) async {
    final provider = Provider.of<CaseDocProvider>(context, listen: false);
    
    // Show a loading indicator in the bottom sheet while we fetch the URL
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching secure document link...')));
    
    final url = await provider.viewDocument(caseItem.id, document.id);
    if (context.mounted) {
      Navigator.pop(context); // Close the options sheet
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch the document view.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to view document.')),
        );
      }
    }
  }

  void _showAuditLogs(BuildContext context) {
    Navigator.pop(context); // Close the options sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaseDocAuditLogSheet(docId: document.id, docTitle: document.title),
    );
  }

  void _managePermissions(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaseDocPermissionsSheet(caseItem: caseItem, document: document),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userWallet = auth.user?.walletAddress ?? '';
    final canManage = userWallet == caseItem.adminWallet || userWallet == document.uploader;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${(document.fileSize / 1024).toStringAsFixed(2)} KB • Uploaded by ${document.uploader.substring(0,6)}...', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: Icon(Icons.visibility, color: Colors.blue.shade700),
            title: Text('View Document', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () => _viewDocument(context),
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.orange.shade700),
            title: Text('View Audit Logs', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () => _showAuditLogs(context),
          ),
          if (canManage) ...[
            const Divider(),
            ListTile(
              leading: Icon(Icons.security, color: Colors.red.shade700),
              title: Text('Manage Permissions', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.red.shade800)),
              onTap: () => _managePermissions(context),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class CaseDocAuditLogSheet extends StatefulWidget {
  final String docId;
  final String docTitle;

  const CaseDocAuditLogSheet({super.key, required this.docId, required this.docTitle});

  @override
  State<CaseDocAuditLogSheet> createState() => _CaseDocAuditLogSheetState();
}

class _CaseDocAuditLogSheetState extends State<CaseDocAuditLogSheet> {
  bool _isLoading = true;
  List<AuditLogModel> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final provider = Provider.of<CaseDocProvider>(context, listen: false);
    try {
      final logs = await provider.fetchDocumentLogs(widget.docId);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load logs';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Audit Logs', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Document: ${widget.docTitle}', style: GoogleFonts.inter(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _logs.isEmpty
                            ? Center(child: Text('No access logs found.', style: GoogleFonts.inter(color: Colors.grey)))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _logs.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(log.action.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text('Wallet: ${log.userWallet}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
                                    trailing: Text(
                                      DateFormat('MMM d, h:mm a').format(log.timestamp),
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CaseDocPermissionsSheet extends StatefulWidget {
  final CaseModel caseItem;
  final CaseDocModel document;

  const CaseDocPermissionsSheet({super.key, required this.caseItem, required this.document});

  @override
  State<CaseDocPermissionsSheet> createState() => _CaseDocPermissionsSheetState();
}

class _CaseDocPermissionsSheetState extends State<CaseDocPermissionsSheet> {
  Future<void> _grantAccess(String targetWallet) async {
    final provider = Provider.of<CaseDocProvider>(context, listen: false);
    final success = await provider.grantDocumentAccess(widget.caseItem.id, widget.document.id, targetWallet, true, false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Access granted!' : 'Failed to grant access')),
      );
      if (success) Navigator.pop(context); // Close sheet to let them reopen and see updated access
    }
  }

  Future<void> _revokeAccess(String targetWallet) async {
    final provider = Provider.of<CaseDocProvider>(context, listen: false);
    final success = await provider.revokeDocumentAccess(widget.caseItem.id, widget.document.id, targetWallet);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Access revoked!' : 'Failed to revoke access')),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine who has access
    final accessList = widget.document.accessControl;
    final accessWallets = accessList.map((e) => e.wallet).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Manage Permissions', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Control who can view this document.', style: GoogleFonts.inter(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.caseItem.participants.length,
                  itemBuilder: (context, index) {
                    final participant = widget.caseItem.participants[index];
                    final hasAccess = accessWallets.contains(participant.wallet);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: hasAccess ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(Icons.person, color: hasAccess ? Colors.green.shade700 : Colors.grey.shade600),
                      ),
                      title: Text(participant.wallet, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
                      subtitle: Text('Role: ${participant.role}', style: GoogleFonts.inter(fontSize: 12)),
                      trailing: hasAccess
                          ? TextButton(
                              onPressed: () => _revokeAccess(participant.wallet),
                              child: Text('Revoke', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
                            )
                          : TextButton(
                              onPressed: () => _grantAccess(participant.wallet),
                              child: Text('Grant', style: GoogleFonts.inter(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
