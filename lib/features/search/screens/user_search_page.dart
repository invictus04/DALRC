import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dapp/features/search/providers/user_search_provider.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Search Users', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<UserSearchProvider>(
        builder: (context, searchProvider, child) {
          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: searchProvider.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by first or last name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              searchProvider.clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Expanded(
                child: searchProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : searchProvider.users.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Enter a name to search.'
                                  : 'No users found.',
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchProvider.users.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final user = searchProvider.users[index];
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
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(user.fullName,
                                      style: GoogleFonts.inter(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    user.fullName,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        user.role,
                                        style: GoogleFonts.inter(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      if (user.phoneNumber.isNotEmpty)
                                        Text(
                                          user.phoneNumber,
                                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
