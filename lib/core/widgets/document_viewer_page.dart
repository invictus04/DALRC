import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:image_network/image_network.dart';

class DocumentViewerPage extends StatelessWidget {
  final String url;
  final String fileType;
  final String title;

  const DocumentViewerPage({
    super.key,
    required this.url,
    required this.fileType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].any((ext) => fileType.toLowerCase().contains(ext));
    final isPdf = fileType.toLowerCase().contains('pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: isPdf
            ? SfPdfViewer.network(url)
            : isImage
                ? ImageNetwork(
                    image: url,
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    fitAndroidIos: BoxFit.contain,
                    fitWeb: BoxFitWeb.contain,
                  )
                : Text('Unsupported file format: $fileType'),
      ),
    );
  }
}
