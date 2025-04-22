import 'package:flutter/material.dart';
import 'edit_profile1.dart';
import 'delete_profile.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF008000),
        appBar: AppBar(
          title: Text(
            'ThatsFit',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF008000),
        ),
        body: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //Photo
                Align(
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.black,
                  ),
                ),
                //Name
                Text(
                  'Muhammad Mirza',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 20),
                //Add Photo Button
                ElevatedButton(
                    onPressed: () {},
                    child: Text('Add Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )),
                SizedBox(height: 20),
                //About Profile
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '  About Profile',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                //About Profile Card
                Container(
                  width: double.infinity,
                  height: 180,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.person,
                                      size: 30, color: Colors.black),
                                  SizedBox(width: 10),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EditProfile1()),
                                        );
                                      },
                                      child: Text('Edit Profile',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20)),
                                    ),
                                  ),
                                ]),
                            SizedBox(height: 10),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.delete,
                                      size: 30, color: Colors.black),
                                  SizedBox(width: 10),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeleteProfilePage(),
                                          ),
                                        );
                                      },
                                      child: Text('Delete Profile',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20)),
                                    ),
                                  ),
                                ]),
                            SizedBox(height: 10),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.logout,
                                      size: 30, color: Colors.black),
                                  SizedBox(width: 10),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Text('Logout',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20)),
                                    ),
                                  ),
                                ]),
                          ],
                        )),
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '  About Us',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 150,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.info, size: 30, color: Colors.black),
                              SizedBox(width: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                child: InkWell(
                                  onTap: () {},
                                  child: Text('Instagram',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 20)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.info, size: 30, color: Colors.black),
                              SizedBox(width: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                child: InkWell(
                                  onTap: () {},
                                  child: Text('Tiktok',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 20)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ], //children
            )));
  }
}
