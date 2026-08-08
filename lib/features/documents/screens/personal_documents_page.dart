import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dapp/features/documents/providers/personal_doc_provider.dart';
import 'package:dapp/core/services/pinata_service.dart';
import 'package:dapp/features/documents/models/personal_doc_model.dart';
import 'dart:math' hide log;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dapp/features/auth/providers/auth_provider.dart';
import 'package:dapp/features/auth/models/user_model.dart';
import 'package:dapp/features/cases/models/audit_log_model.dart';
import 'dart:developer';

import 'package:dapp/features/search/models/search_user_model.dart';

class PersonalDocumentsPage extends StatefulWidget {
  const PersonalDocumentsPage({super.key});

  @override
  State<PersonalDocumentsPage> createState() => _PersonalDocumentsPageState();
}

class _PersonalDocumentsPageState extends State<PersonalDocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PersonalDocProvider>(context, listen: false);
      provider.fetchOwnedDocs();
      provider.fetchSharedDocs();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final provider = Provider.of<PersonalDocProvider>(context, listen: false);
      if (_tabController.index == 0 && provider.ownedDocs.isEmpty) {
        provider.fetchOwnedDocs();
      } else if (_tabController.index == 1 && provider.sharedDocs.isEmpty) {
        provider.fetchSharedDocs();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showUploadDialog(
    BuildContext context,
    PersonalDocProvider provider,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    provider.clearUploadState();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<PersonalDocProvider>(
          builder: (context, dialogProvider, child) {
            final isUploading = dialogProvider.isUploading;
            final selectedFile = dialogProvider.selectedFile;

            return AlertDialog(
              title: Text(
                'Upload Document',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles();
                        if (result != null) {
                          dialogProvider.setSelectedFile(result.files.first);
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        selectedFile != null
                            ? selectedFile.name
                            : 'Select File',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isUploading
                          ? null
                          : () {
                            dialogProvider.clearUploadState();
                            Navigator.pop(context);
                          },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isUploading
                          ? null
                          : () async {
                            if (titleController.text.trim().isEmpty ||
                                selectedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Title and File are required'),
                                ),
                              );
                              return;
                            }

                            dialogProvider.setUploading(true);

                            try {
                              String? realCid;
                              if (selectedFile.path != null) {
                                realCid =
                                    await PinataService.uploadFileToPinata(
                                      File(selectedFile.path!),
                                    );
                              }

                              if (realCid == null) {
                                dialogProvider.setUploading(false);
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to upload to Pinata IPFS',
                                      ),
                                    ),
                                  );
                                return;
                              }

                              final success = await dialogProvider
                                  .uploadDocument(
                                    title: titleController.text.trim(),
                                    description:
                                        descriptionController.text.trim(),
                                    fileType:
                                        selectedFile.extension ?? 'unknown',
                                    fileSize: selectedFile.size,
                                    ipfsCid: realCid,
                                    encrypted: true,
                                  );

                              if (success) {
                                dialogProvider.clearUploadState();
                                if (context.mounted)
                                  Navigator.pop(context, true);
                              } else {
                                dialogProvider.setUploading(false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to upload document',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              dialogProvider.setUploading(false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to upload document'),
                                  ),
                                );
                              }
                            }
                          },
                  child:
                      isUploading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDocOptionsBottomSheet(
    BuildContext context,
    PersonalDocModel doc,
    PersonalDocProvider provider,
    bool isOwned,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Document Options',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOwned) ...[
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: Text('Share', style: GoogleFonts.inter()),
                  onTap: () {
                    Navigator.pop(context);
                    _showShareDialog(context, doc, provider);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.history, color: Colors.green),
                title: Text('Audit Logs', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _showLogsBottomSheet(context, doc, provider);
                },
              ),
              if (isOwned) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete',
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, doc, provider);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showShareDialog(
    BuildContext context,
    PersonalDocModel doc,
    PersonalDocProvider provider,
  ) async {
    final searchController = TextEditingController();
    List<SearchUserModel> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Share Document',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search User by Name, Email or Phone',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            if (searchController.text.isEmpty) return;
                            setState(() => isSearching = true);
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );

                            final query = searchController.text.trim();
                            final results = await authProvider.searchUsers(
                              query,
                            );

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
                      const CircularProgressIndicator()
                    else if (searchResults.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            final wallet = user.walletAddress;
                            log("doc: ${doc.id}, wallet: ${wallet}");
                            return ListTile(
                              title: Text('${user.fullName}'),
                              subtitle: Text(
                                wallet,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing:
                                  wallet == 'No Wallet'
                                      ? null
                                      : PopupMenuButton<String>(
                                        onSelected: (action) async {
                                          bool success = false;
                                          if (action == 'share') {
                                            success = await provider
                                                .shareDocument(doc.id, wallet);
                                          } else if (action == 'unshare') {
                                            success = await provider
                                                .unshareDocument(
                                                  doc.id,
                                                  wallet,
                                                );
                                          }
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? '${action == 'share' ? 'Shared' : 'Unshared'} successfully'
                                                      : 'Failed to $action',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: 'share',
                                                child: Text('Share Access'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'unshare',
                                                child: Text(
                                                  'Revoke Access',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                      ),
                            );
                          },
                        ),
                      )
                    else
                      const Text('No users found.'),
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

  Future<void> _showLogsBottomSheet(
    BuildContext context,
    PersonalDocModel doc,
    PersonalDocProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<AuditLogModel>>(
              future: provider.fetchDocumentLogs(doc.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data ?? [];

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Audit Logs',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          logs.isEmpty
                              ? const Center(child: Text('No logs available'))
                              : ListView.separated(
                                controller: scrollController,
                                itemCount: logs.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      log.action,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'By: ${log.userWallet}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          log.timestamp.toString().split(
                                            '.',
                                          )[0],
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    PersonalDocModel doc,
    PersonalDocProvider provider,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Document',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${doc.title}"? This action cannot be undone.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final success = await provider.deleteDocument(doc.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Document deleted' : 'Failed to delete',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocList(
    List<PersonalDocModel> docs,
    bool isLoading,
    String? error,
    VoidCallback onRetry,
    bool isOwned,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(error, style: GoogleFonts.inter(color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (docs.isEmpty) {
      return Center(
        child: Text(
          'No documents found.',
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.description, color: Colors.blue.shade700),
            ),
            title: Text(
              doc.title,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (doc.description.isNotEmpty) ...[
                  Text(
                    doc.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${(doc.fileSize / 1024 / 1024).toStringAsFixed(2)} MB • ${doc.fileType}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                final provider = Provider.of<PersonalDocProvider>(
                  context,
                  listen: false,
                );
                _showDocOptionsBottomSheet(context, doc, provider, isOwned);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade800,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade800,
              tabs: const [
                Tab(text: 'My Documents'),
                Tab(text: 'Shared With Me'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PersonalDocProvider>(
              builder: (context, provider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDocList(
                      provider.ownedDocs,
                      provider.isLoadingOwned,
                      provider.errorOwned,
                      provider.fetchOwnedDocs,
                      true,
                    ),
                    _buildDocList(
                      provider.sharedDocs,
                      provider.isLoadingShared,
                      provider.errorShared,
                      provider.fetchSharedDocs,
                      false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          _tabController.index == 0
              ? Consumer<PersonalDocProvider>(
                builder: (context, provider, child) {
                  return FloatingActionButton.extended(
                    onPressed: () => _showUploadDialog(context, provider),
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      'Upload',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  );
                },
              )
              : null,
    );
  }
}
