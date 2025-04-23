import 'package:dapp/starting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/appkit_modal.dart';
import 'package:reown_appkit/modal/appkit_modal_impl.dart';
import 'package:reown_appkit/modal/widgets/public/appkit_modal_connect_button.dart';

class LogsPage extends StatefulWidget {
  final ReownAppKitModal appKitModal;

  const LogsPage({Key? key, required this.appKitModal}) : super(key: key);

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<Map<String, dynamic>> logs = [
    {
      'timestamp': '2023-06-15 14:30:22',
      'action': 'Upload',
      'user': 'John Smith',
      'txHash': '0x4a7b...c3d2',
      'status': 'Success',
    },
    {
      'timestamp': '2023-06-15 14:28:10',
      'action': 'Verification',
      'user': 'Sarah Johnson',
      'txHash': '0x8f2e...a1b4',
      'status': 'Success',
    },
    {
      'timestamp': '2023-06-15 14:25:45',
      'action': 'Access Request',
      'user': 'Michael Brown',
      'txHash': '0x3c5d...e7f9',
      'status': 'Pending',
    },
    {
      'timestamp': '2023-06-15 14:22:33',
      'action': 'Execution',
      'user': 'System',
      'txHash': '0x9b1a...d5c8',
      'status': 'Success',
    },
    {
      'timestamp': '2023-06-15 14:20:18',
      'action': 'Update',
      'user': 'Emily Davis',
      'txHash': '0x2e6f...b7d3',
      'status': 'Failed',
    },

  ];

  @override
  void initState() {
    super.initState();
    // Listen for disconnection events
    widget.appKitModal.addListener(_handleConnectionChange);
  }

  @override
  void dispose() {
    widget.appKitModal.removeListener(_handleConnectionChange);
    super.dispose();
  }

  void _handleConnectionChange() {
    if (!widget.appKitModal.isConnected) {
      // Exit the app when disconnected
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => StartingPage()),
              (Route<dynamic> route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blockchain Logs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logs refreshed')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Transaction Hash', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(log['timestamp'], style: TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: Text(log['action'])),
                        Expanded(flex: 2, child: Text(log['user'])),
                        Expanded(
                          flex: 2,
                          child: SelectableText(
                            log['txHash'],
                            style: TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    // Logout functionality
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Perform logout
                              widget.appKitModal.disconnect();
                              // Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logged out successfully')),
                              );
                              SystemNavigator.pop();
                            },
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}