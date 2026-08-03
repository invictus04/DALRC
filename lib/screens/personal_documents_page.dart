import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/personal_doc_provider.dart';
import '../../services/pinata_service.dart';
import '../../models/personal_doc_model.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PersonalDocumentsPage extends StatefulWidget {
  const PersonalDocumentsPage({super.key});

  @override
  State<PersonalDocumentsPage> createState() => _PersonalDocumentsPageState();
}

class _PersonalDocumentsPageState extends State<PersonalDocumentsPage> with SingleTickerProviderStateMixin {
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

  Future<void> _showUploadDialog(BuildContext context, PersonalDocProvider provider) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isUploading = false;
    PlatformFile? selectedFile;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Upload Document', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles();
                        if (result != null) {
                          setDialogState(() {
                            selectedFile = result.files.first;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(selectedFile != null ? selectedFile!.name : 'Select File'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (titleController.text.trim().isEmpty || selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and File are required')));
                      return;
                    }
                    
                    setDialogState(() {
                      isUploading = true;
                    });
                    
                    try {
                     
                      final pinataJwt = dotenv.env['PINATA_JWT_TOKEN'] ?? '';
                      
                      String? realCid;
                      if (selectedFile!.path != null) {
                        realCid = await PinataService.uploadFileToPinata(File(selectedFile!.path!), pinataJwt);
                      }
                      
                      if (realCid == null) {
                        setDialogState(() {
                          isUploading = false;
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload to Pinata IPFS')));
                        return;
                      }
                      
                      final success = await provider.uploadDocument(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        fileType: selectedFile!.extension ?? 'unknown',
                        fileSize: selectedFile!.size,
                        ipfsCid: realCid,
                        encrypted: true,
                      );
                      
                      if (success) {
                        if (mounted) Navigator.pop(context, true);
                      } else {
                        setDialogState(() {
                          isUploading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document')));
                        }
                      }
                    } catch (e) {
                      setDialogState(() {
                        isUploading = false;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document')));
                      }
                    }
                  },
                  child: isUploading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Upload'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildDocList(List<PersonalDocModel> docs, bool isLoading, String? error, VoidCallback onRetry) {
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
        child: Text('No documents found.', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 16)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.description, color: Colors.blue.shade700),
            ),
            title: Text(doc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (doc.description.isNotEmpty) ...[
                  Text(doc.description, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                ],
                Text('${(doc.fileSize / 1024 / 1024).toStringAsFixed(2)} MB • ${doc.fileType}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Future feature: View, Share, Delete
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
                    _buildDocList(provider.ownedDocs, provider.isLoadingOwned, provider.errorOwned, provider.fetchOwnedDocs),
                    _buildDocList(provider.sharedDocs, provider.isLoadingShared, provider.errorShared, provider.fetchSharedDocs),
                  ],
                );
              }
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Consumer<PersonalDocProvider>(
              builder: (context, provider, child) {
                return FloatingActionButton.extended(
                  onPressed: () => _showUploadDialog(context, provider),
                  icon: const Icon(Icons.upload_file),
                  label: Text('Upload', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                );
              }
            )
          : null,
    );
  }
}
