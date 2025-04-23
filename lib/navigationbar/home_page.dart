import 'package:dapp/navigationbar/about_case_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {


  final _colors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.amber,
    Colors.deepPurpleAccent,
  ];


  void _openBottomDrawer() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _colors.length,
                  itemBuilder: (context, index) => Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Category ${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        elevation: 5,
        onPressed: _openBottomDrawer,
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              SizedBox(height: 30),
          Center(
            child: Container(
              decoration: BoxDecoration(
                  boxShadow: [
              BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 30,
              offset: Offset(0, 15),
              )
                  ],
            ),
            child: Image.asset(
              'assets/bank-locker.png',
              height: 250,
              width: 250,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          "Welcome Back,",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        Text(
          "Here are your cases",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Cases",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue[900],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AboutCasePage(),));
                });
              },
              child: Text(
                "View All",
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          height: 350,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
          BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 3,
          blurRadius: 10,
          offset: Offset(0, 5),
          )
              ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    'Case Title ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  subtitle: Text(
                    'Case description summary...',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.blue[800],
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      SizedBox(height: 20),
      ],
    ),
    ),
    ),
    );
  }
}