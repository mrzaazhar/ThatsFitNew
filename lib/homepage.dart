import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'profile_page.dart';
//import 'steps_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected index
  int _current = 0; // Track current carousel page
  final CarouselController _carouselController =
      CarouselController(); // Controller for carousel

  // List of widgets for each tab
  final List<Widget> _widgetOptions = <Widget>[
    Text('Home Screen'), // Replace with your Home widget
    Text('Search Screen'), // Replace with your Search widget
    Text('Back Screen'), // Replace with your Back widget
    Text('Logout Screen'), // Replace with your Logout widget
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF008000), // Background color
      appBar: AppBar(
        title: Text(
          'ThatsFit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
        backgroundColor: Color(0xFF008000),
        actions: [
          IconButton(
            icon: Icon(Icons.person, size: 40),
            onPressed: () {
              // Handle user profile action
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Step Count Section
            Column(
              children: [
                SizedBox(height: 10),
                CarouselSlider(
                  carouselController:
                      CarouselSliderController(), // Use correct controller type
                  options: CarouselOptions(
                    height: 160,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 3),
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enlargeCenterPage: true,
                    enlargeFactor: 10,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                      });
                    },
                  ),
                  items: [
                    // First Slide - Step Count
                    Container(
                      width: 600,
                      //margin: EdgeInsets.symmetric(horizontal: 5.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFbfbfbf),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Step Count',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: 0.7,
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF33443c),
                                  ),
                                  strokeWidth: 10,
                                ),
                              ),
                              SizedBox(width: 20),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'View More',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6e9277),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Second Slide - Daily Goal
                    Container(
                      width: 600,
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFbfbfbf),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            '7000 / 10000',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          Text(
                            'steps',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Third Slide - Weekly Progress
                    Container(
                      width: 600,
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFbfbfbf),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Weekly Progress',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            '35,000 steps',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          Text(
                            'Great progress!',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10), // Space between carousel and dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      [0, 1, 2].map((index) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _current == index
                                    ? Color(0xFF33443c) // Active dot color
                                    : Colors.white.withOpacity(
                                      0.4,
                                    ), // Inactive dot color
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),
            // New Container for Create Workout Button
            Container(
              padding: EdgeInsets.all(20),
              height: 400,
              width: 500,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/JPG/workout_image.jpg'),
                  fit: BoxFit.cover,
                ),
                color: Color(0xFFbfbfbf),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Align the button to the bottom
                children: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle create workout action
                      },
                      child: Text(
                        'Create Workout',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'DM Sans',
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6e9277),
                        padding: EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Color(0xFF008000), // Background color of the navigation bar
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GNav(
            gap: 8,
            color: Colors.white, // Color for unselected items
            activeColor: Colors.white, // Color for selected item
            iconSize: 24,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            duration: Duration(milliseconds: 400),
            tabBackgroundColor:
                Colors.green, // Background color for selected tab
            tabs: [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.search, text: 'Search'),
              GButton(icon: Icons.arrow_back, text: 'Back'),
              GButton(icon: Icons.logout, text: 'Logout'),
            ],
            selectedIndex: _selectedIndex, // Set the current index
            onTabChange: (index) {
              _onItemTapped(index); // Handle tab change
            },
          ),
        ),
      ),
    );
  }
}
