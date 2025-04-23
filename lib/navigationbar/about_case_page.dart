import 'package:flutter/material.dart';

class AboutCasePage extends StatefulWidget {
  @override
  _AboutCasePageState createState() => _AboutCasePageState();
}

class _AboutCasePageState extends State<AboutCasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color _appBarColor = Colors.blue;
  Color _statusColor = Colors.blue;
  List<Color> _tabTextColors = [Colors.blue, Colors.red, Colors.green];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _appBarColor = Colors.blue;
          _statusColor = Colors.blue;
          _tabTextColors = [Colors.blue, Colors.red, Colors.green];
          break;
        case 1:
          _appBarColor = Colors.red;
          _statusColor = Colors.red;
          _tabTextColors = [Colors.blue, Colors.red, Colors.green];
          break;
        case 2:
          _appBarColor = Colors.green;
          _statusColor = Colors.green;
          _tabTextColors = [Colors.blue, Colors.red, Colors.green];
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cases'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black87,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black87,
          tabs: [
            Tab(
              child: Text(
                'All Cases',
                style: TextStyle(
                  color: _tabTextColors[0],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Tab(
              child: Text(
                'Pending',
                style: TextStyle(
                  color: _tabTextColors[1],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Tab(
              child: Text(
                'Done',
                style: TextStyle(
                  color: _tabTextColors[2],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaseList('All Cases'),
          _buildCaseList('Pending'),
          _buildCaseList('Done'),
        ],
      ),
    );
  }

  Widget _buildCaseList(String status) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Case No. ${index + 1}'),
                    Text(
                      '${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Case Title ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text('Description of case ${index + 1} goes here...'),
                SizedBox(height: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: _statusColor.withOpacity(0.3),
                        blurRadius: 5.0,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
