import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_note_page.dart';
import 'edit_note_page.dart';
import 'login.dart';
import 'view_note_page.dart';

class NotesPage extends StatefulWidget {
  final int userId;

  NotesPage({required this.userId});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> notes = [];
  List<dynamic> filteredNotes = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  /// Fetch Notes
  Future<void> fetchNotes() async {
    setState(() => isLoading = true);

    final String apiUrl = "https://www.csic410-project.infinityfreeapp.com/get_notes.php";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            notes = data['notes'];
            filteredNotes = notes;
          });
        } else {
          showSnackbar(data['message'] ?? 'Failed to fetch notes');
        }
      }
    } catch (e) {
      showSnackbar('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Delete Note
  Future<void> deleteNote(int noteId) async {
    final String apiUrl = "https://www.csic410-project.infinityfreeapp.com/delete_note.php";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"note_id": noteId}),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          notes.removeWhere((note) => note['id'] == noteId);
          filteredNotes = notes;
        });
        showSnackbar('Note deleted successfully!');
      } else {
        showSnackbar(data['message'] ?? 'Failed to delete note');
      }
    } catch (e) {
      showSnackbar('Error: $e');
    }
  }

  /// Show Snackbar
  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Navigate to Add Note Page
  Future<void> navigateToAddNotePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNotePage(userId: widget.userId),
      ),
    );

    if (result == true) {
      fetchNotes(); // Refresh the notes list after adding
    }
  }

  /// Navigate to Edit Note Page
  Future<void> navigateToEditNotePage(Map note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNotePage(
          noteId: note['id'],
          initialTitle: note['title'],
          initialContent: note['content'],
        ),
      ),
    );

    if (result == true) {
      fetchNotes(); // Refresh the notes list after editing
    }
  }

  /// Navigate to View Full Note Page
  void navigateToViewNotePage(Map note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewNotePage(
          title: note['title'],
          content: note['content'],
        ),
      ),
    );
  }

  /// Search Notes
  void searchNotes(String query) {
    setState(() {
      filteredNotes = notes
          .where((note) =>
          note['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back arrow
        title: Text(
          'My Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white, // White text color
          ),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white), // Logout icon
            tooltip: 'Logout',
            onPressed: () {
              // Navigate to the Login Page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600, // Icon color
                ),
                labelText: 'Search by Title',
                labelStyle: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: true, // Enable background color
                fillColor: Colors.grey.shade100, // Background color for TextField
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  borderSide: BorderSide.none, // Remove default border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300, // Border color when not focused
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.red.shade400, // Border color when focused
                    width: 2,
                  ),
                ),
                hintText: 'Type to search...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),

              onChanged: searchNotes,
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                ? Center(child: Text('No Notes Found'))
                : ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return Card(
                  margin: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(note['title']),
                    subtitle: Text(
                      note['content'].length > 50
                          ? '${note['content'].substring(0, 50)}...'
                          : note['content'],
                    ),
                    onTap: () => navigateToViewNotePage(note),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => navigateToEditNotePage(note),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteNote(note['id']),
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
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddNotePage,
        child: Icon(Icons.add,color: Colors.white,),
        backgroundColor: Colors.red,
      ),
    );
  }
}
