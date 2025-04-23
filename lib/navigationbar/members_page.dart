import 'package:flutter/material.dart';

class MembersPage extends StatelessWidget {
  final List<Map<String, dynamic>> members = [
    {
      'name': 'John Smith',
      'joinDate': '2023-01-15',
      'role': 'Judge',
      'permissions': 'Read and Write',
      'avatar': 'J',
    },
    {
      'name': 'Sarah Johnson',
      'joinDate': '2023-02-20',
      'role': 'Lawyer',
      'permissions': 'Write',
      'avatar': 'S',
    },
    {
      'name': 'Michael Brown',
      'joinDate': '2023-03-10',
      'role': 'Police',
      'permissions': 'Read',
      'avatar': 'M',
    },
    {
      'name': 'Emily Davis',
      'joinDate': '2023-04-05',
      'role': 'Consumer',
      'permissions': 'Read',
      'avatar': 'E',
    },
    {
      'name': 'Robert Wilson',
      'joinDate': '2023-05-12',
      'role': 'Lawyer',
      'permissions': 'Read and Write',
      'avatar': 'R',
    },
  ];

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Judge':
        return Colors.deepPurple;
      case 'Lawyer':
        return Colors.blue;
      case 'Police':
        return Colors.green;
      case 'Consumer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'Read':
        return Icons.visibility;
      case 'Write':
        return Icons.edit;
      case 'Read and Write':
        return Icons.edit_attributes;
      default:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Members'), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          // Header Row
          // Container(
          //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[100],
          //     border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          //   ),
          //   child: Row(
          //     children: [
          //       SizedBox(
          //         width: 16,
          //         child: Text(
          //           '#',
          //           style: TextStyle(fontWeight: FontWeight.bold),
          //         ),
          //       ),
          //       SizedBox(width: 16),
          //       Expanded(
          //         child: Text(
          //           'Name',
          //           style: TextStyle(fontWeight: FontWeight.bold),
          //         ),
          //       ),
          //       Expanded(
          //         child: Text(
          //           'Joined',
          //           style: TextStyle(fontWeight: FontWeight.bold),
          //         ),
          //       ),
          //       Expanded(
          //         child: Text(
          //           'Role',
          //           style: TextStyle(fontWeight: FontWeight.bold),
          //         ),
          //       ),
          //       Expanded(
          //         child: Text(
          //           'Permissions',
          //           style: TextStyle(fontWeight: FontWeight.bold),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // Members List
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),

                    title: Row(
                      children: [
                        SizedBox(width: 16, child: Text('${index + 1}')),
                        SizedBox(width: 16),
                        Expanded(child: Text(member['name'], )),
                        Expanded(child: Text(member['joinDate'])),
                        Expanded(
                          child: Chip(
                            label: Text(member['role']),
                            backgroundColor: _getRoleColor(
                              member['role'],
                            ).withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: _getRoleColor(member['role']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // SizedBox(width: 4),
                        Icon(
                          _getPermissionIcon(member['permissions']),
                          size: 18,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
