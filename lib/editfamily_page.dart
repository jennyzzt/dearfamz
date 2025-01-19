import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dearfamz/widgets/appbar_ttitle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditFamilyPage extends StatefulWidget {
  const EditFamilyPage({super.key});

  @override
  State<EditFamilyPage> createState() => _EditFamilyPageState();
}

class _EditFamilyPageState extends State<EditFamilyPage> {
  /// A list to hold the current user’s family members (their UIDs).
  List<String> familyMemberUids = [];

  /// A list to hold the corresponding names for displaying in the UI.
  List<String> familyMembersNames = [];

  /// A list to hold the corresponding emails for displaying in the UI.
  List<String> familyMembersEmails = [];

  /// Text controller for searching by email.
  final TextEditingController _searchEmailController = TextEditingController();

  /// The searched user’s UID (found by email)
  String? _searchedUserUid;

  /// The searched user’s Name (found by email)
  String? _searchedUserName;

  /// The searched user’s Email (found by email)
  String? _searchedUserEmail;

  /// An error message if a search fails
  String? _searchErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFamilyMembers();
  }

  /// Fetch the current user's familyMembers (UIDs) from Firestore,
  /// then fetch their [name] & [email].
  Future<void> _fetchFamilyMembers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Not logged in, nothing to fetch.

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!docSnapshot.exists) {
      setState(() {
        familyMemberUids = [];
        familyMembersNames = [];
        familyMembersEmails = [];
      });
      return;
    }

    final data = docSnapshot.data();
    if (data == null) {
      setState(() {
        familyMemberUids = [];
        familyMembersNames = [];
        familyMembersEmails = [];
      });
      return;
    }

    // Expecting a List<String> stored under "familyMembers" (UIDs, not emails)
    if (data['familyMembers'] is List) {
      final List<String> uidList = List<String>.from(data['familyMembers']);
      setState(() {
        familyMemberUids = uidList;
      });

      // Now fetch each UID’s name/email and build our lists
      await _fetchDataForFamilyUids(uidList);
    } else {
      setState(() {
        familyMemberUids = [];
        familyMembersNames = [];
        familyMembersEmails = [];
      });
    }
  }

  /// For each UID in [uidList], fetch the user document and retrieve [name] & [email].
  /// Then store those in the respective lists in the same order as [uidList].
  Future<void> _fetchDataForFamilyUids(List<String> uidList) async {
    if (uidList.isEmpty) {
      setState(() {
        familyMembersNames = [];
        familyMembersEmails = [];
      });
      return;
    }

    try {
      // Firestore 'whereIn' supports up to 10 items. If more, handle differently.
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uidList)
          .get();

      // Create a map from UID -> (name, email)
      final Map<String, Map<String, String>> uidToData = {};

      for (var doc in querySnap.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? 'Unknown';
        final email = data['email'] as String? ?? 'Unknown';
        uidToData[doc.id] = {
          'name': name,
          'email': email,
        };
      }

      // Rebuild the name & email arrays in the same order as uidList
      final namesInOrder = <String>[];
      final emailsInOrder = <String>[];

      for (var uid in uidList) {
        final info = uidToData[uid];
        if (info != null) {
          namesInOrder.add(info['name'] ?? 'Unknown');
          emailsInOrder.add(info['email'] ?? 'Unknown');
        } else {
          namesInOrder.add('Unknown');
          emailsInOrder.add('Unknown');
        }
      }

      setState(() {
        familyMembersNames = namesInOrder;
        familyMembersEmails = emailsInOrder;
      });
    } catch (e) {
      debugPrint('Error fetching data for family UIDs: $e');
      setState(() {
        familyMembersNames = [];
        familyMembersEmails = [];
      });
    }
  }

  /// Searches for a user by email in Firestore (collects name & email).
  Future<void> _searchForUserByEmail(String email) async {
    setState(() {
      _searchedUserUid = null;
      _searchedUserName = null;
      _searchedUserEmail = null;
      _searchErrorMessage = null;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      setState(() {
        _searchErrorMessage = 'No user found with that email.';
      });
      return;
    }

    final userDoc = querySnapshot.docs.first;
    final userData = userDoc.data();

    // Save the doc's ID (UID), name, and email
    setState(() {
      _searchedUserUid = userDoc.id;
      _searchedUserName = userData['name'] as String? ?? 'Unknown';
      _searchedUserEmail = userData['email'] as String? ?? 'Unknown';
    });
  }

  /// Adds the searched user's UID to the current user’s familyMembers list.
  Future<void> _addSearchedUserToFamily() async {
    if (_searchedUserUid == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'familyMembers': FieldValue.arrayUnion([_searchedUserUid])
    });

    // Refresh the family members
    await _fetchFamilyMembers();

    // Reset after adding
    setState(() {
      _searchedUserUid = null;
      _searchedUserName = null;
      _searchedUserEmail = null;
      _searchEmailController.clear();
    });
  }

  /// Show a confirmation dialog before removing a family member
  Future<void> _confirmRemoveFamilyMember(String memberUid, String name) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Family Member'),
          content: Text('Are you sure you want to remove "$name" from your family?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    // If user confirms, proceed with actual removal
    if (shouldRemove == true) {
      _removeFamilyMember(memberUid);
    }
  }

  /// Removes a family member from the current user's familyMembers list.
  Future<void> _removeFamilyMember(String memberUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'familyMembers': FieldValue.arrayRemove([memberUid])
    });

    // Refresh the family members
    await _fetchFamilyMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar remains unchanged
      appBar: AppBar(
        centerTitle: true,
        title: AppBarTitle(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SEARCH AREA ---
            TextField(
              controller: _searchEmailController,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                hintText: 'Search by email',
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.black,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
              ),
              onPressed: () async {
                await _searchForUserByEmail(
                  _searchEmailController.text.trim(),
                );
              },
              child: const Text(
                'Search',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),

            // Error message
            if (_searchErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _searchErrorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Show the found user's name & email in a single row with a + icon
            if (_searchedUserUid != null &&
                _searchedUserName != null &&
                _searchedUserEmail != null) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show name & email in two lines
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _searchedUserName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _searchedUserEmail!,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _addSearchedUserToFamily,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add to Family',
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text(
              'Family Members on DearFamz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),

            // If no family members
            if (familyMemberUids.isEmpty || 
              familyMemberUids.length != familyMembersNames.length || 
              familyMemberUids.length != familyMembersEmails.length) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              // Show each family member in a grey rectangle
              ListView.builder(
                shrinkWrap: true,
                itemCount: familyMemberUids.length,
                itemBuilder: (context, index) {
                  final memberUid = familyMemberUids[index];
                  final name = familyMembersNames.isNotEmpty
                      ? familyMembersNames[index]
                      : 'Unknown';
                  final email = familyMembersEmails.isNotEmpty
                      ? familyMembersEmails[index]
                      : 'Unknown';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(email),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Remove from Family',
                        onPressed: () => _confirmRemoveFamilyMember(memberUid, name),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}