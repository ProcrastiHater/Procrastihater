///********************************************************************************
/// Name: profile_picture_selection.dart
///
/// Description: Shows 6 images a user can select and change their profile picture
/// too
///********************************************************************************
library;

// Dart imports
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// All of the profile photos
  final List<String> imageUrls = [
    'https://picsum.photos/id/219/367/267',
    'https://picsum.photos/id/237/367/267',
    'https://picsum.photos/id/306/367/267',
    'https://picsum.photos/id/443/367/267',
    'https://picsum.photos/id/433/367/267',
    'https://picsum.photos/id/431/367/267'
  ];

  final CollectionReference MAIN_COLLECTION = FirebaseFirestore.instance.collection('UID');
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  //Reference to user's document in Firestore
  DocumentReference userRef = MAIN_COLLECTION.doc(uid);

class ProfilePictureSelectionScreen extends StatelessWidget {
  const ProfilePictureSelectionScreen({super.key});


//********************************************************************************
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Picture Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Choose a Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Grid of images
            Expanded(
              child: GridView.builder(
                // Random grid to make things look nice
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // 2 images per row
                  crossAxisCount: 2, 
                  crossAxisSpacing: 16.0, 
                  mainAxisSpacing: 16.0,
                ),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  // Making the cute card thing with the edges
                  return Card(
                    elevation: 4.0, // Add a shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0), 
                      child: GestureDetector(
                        onTap: () async {
                          // Update the user's profile picture in Firebase
                          await FirebaseAuth.instance.currentUser!.updatePhotoURL(imageUrls[index]);
                          await FirebaseAuth.instance.currentUser!.reload();
                          await userRef.set({
                            "pfp":  FirebaseAuth.instance.currentUser!.photoURL
                          }, SetOptions(merge: true));

                          // Return true to indicate the profile picture was updated
                          Navigator.pop(context, true);
                        },
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover, 
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}