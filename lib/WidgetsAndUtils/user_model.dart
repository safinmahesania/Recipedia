import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  Future<String?> addUser(
      {required int userID,
      required String name,
      required String email,
      required String profilePictureURL}) async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      // Call the user's CollectionReference to add a new user
      await users.doc(userID.toString()).set({
        'email': email,
        'name': name,
        'profilePictureURL': profilePictureURL
      });
      return 'success';
    } catch (e) {
      return 'Error adding user';
    }
  }

  Future<List<Map<String, dynamic>>> usersList() async {
    List<Map<String, dynamic>> usersList = [];
    List<String> userIDs = await getUserIdsList();
    CollectionReference users =
    FirebaseFirestore.instance.collection('users');
    for (int i = 0; i < userIDs.length; i++) {
      final snapshot = await users.doc(userIDs[i]).get();
      final data = snapshot.data() as Map<String, dynamic>;
      usersList.add({'userID': userIDs[i], 'name': data['name'], 'email': data['email']},);
    }
    return usersList;
  }

  Future<List<String>> getUserIdsList() async {
    List<String> usersIDs = [];
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('users').get();
    for (var doc in snapshot.docs) {
      usersIDs.add(doc.id);
    }
    return usersIDs;
  }

  Future<String?> updateUser({
    required String userID,
    required String key,
    required String data,
  }) async {
    try {
      FirebaseFirestore.instance.collection('users').doc(userID).update({
        key: data,
      });
      return 'success';
    } catch (e) {
      return 'Error adding user';
    }
  }

  Future<String?> getUserID(String email) async {
    try {
      String? id;
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get()
          .then((value) {
        id = value.docs.first.id;
      });
      return id;
    } catch (e) {
      return 'Error fetching user';
    }
  }

  Future<String?> getUserData(String userID, String key) async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      final snapshot = await users.doc(userID).get();
      final data = snapshot.data() as Map<String, dynamic>;
      return data[key];
    } catch (e) {
      return 'Error fetching user';
    }
  }

  Future<bool> checkIfEmailExists(String email) async {
    bool isExists = false;
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email',
              isEqualTo:
                  email) // Search for documents with email field equal to user's input
          .get();

      if (snapshot.docs.isNotEmpty) {
        isExists = true;
      }
      return isExists;
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUsersCount() async {
    int count = await FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((value) => value.size);
    return count;
  }

  //Future<List<String>> getDocumentIds(String collectionPath) async {
  Future<String> getDocumentIds() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    List<String> documentIds = [];
    querySnapshot.docs.forEach((doc) {
      documentIds.add(doc.id);
    });

    if(documentIds.isEmpty){
      return '100';
    }
    else
      {
        String lastUserID = documentIds.last;
        print(lastUserID);
        return lastUserID;
      }
    //return lastUserID;
  }
}
