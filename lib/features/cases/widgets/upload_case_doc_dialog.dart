import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:dapp/features/cases/models/case_model.dart';
import 'package:dapp/features/cases/providers/case_doc_provider.dart';

class UploadCaseDocDialog extends StatefulWidget {
  final CaseModel caseItem;

  const UploadCaseDocDialog({super.key, required this.caseItem});

  @override
  State<UploadCaseDocDialog> createState() => _UploadCaseDocDialogState();
}

class _UploadCaseDocDialogState extends State<UploadCaseDocDialog> {
  File? _selectedFile;
  final _titleController = TextEditingController();
  bool _isUploading = false;
  bool _shareWithAll = true;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.single.name;
        }
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and provide a title.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Build access control list
    List<Map<String, dynamic>> accessControl = [];
    if (_shareWithAll) {
      for (var p in widget.caseItem.participants) {
        accessControl.add({
          'wallet': p.wallet,
          'canView': true,
          'canDelete': false,
        });
      }
    }

    final provider = Provider.of<CaseDocProvider>(context, listen: false);
    final success = await provider.uploadCaseDocument(
      widget.caseItem.id,
      _titleController.text.trim(),
      _selectedFile!,
      accessControl,
    );

    setState(() {
      _isUploading = false;
    });

    if (context.mounted) {
      Navigator.pop(context); // close bottom sheet
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully to the case!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upload Case Document', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a document to case #${widget.caseItem.caseNumber}. It will be encrypted and stored on IPFS.',
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          Text('Document Title', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g. Affidavit_John_Doe.pdf',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          
          Text('File Selection', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
              ),
              child: Center(
                child: _selectedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, color: Colors.blue.shade700),
                          const SizedBox(height: 4),
                          Text('Tap to select file', style: GoogleFonts.inter(color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_selectedFile!.path.split(Platform.pathSeparator).last, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.green.shade800), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Share with Participants', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Automatically grant view access to all ${widget.caseItem.participants.length} case participants.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            value: _shareWithAll,
            activeColor: Colors.blue.shade800,
            onChanged: (val) => setState(() => _shareWithAll = val),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Upload to Case', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
