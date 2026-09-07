import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'note_editor_screen.dart';
import '../services/api_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<dynamic> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notes = await ApiService.getNotes();
      notes.sort((a, b) {
        final aPinned = a['isPinned'] == true;
        final bPinned = b['isPinned'] == true;
        if (aPinned == bPinned) return 0;
        return aPinned ? -1 : 1;
      });
      setState(() => _notes = notes);
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await ApiService.deleteNote(id);
      _loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _togglePin(Map<String, dynamic> note) async {
    final currentlyPinned = note['isPinned'] == true;
    try {
      await ApiService.togglePin(note['_id'], !currentlyPinned);
      _loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Row(
                children: [ 
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.toString().replaceAll('Exception: ', ''),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.grey[700]!.withOpacity(0.85),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            // margin: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openNoteEditor({Map<String, dynamic>? note}) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
    );
    if (changed == true) {
      _loadNotes();
    }
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete ${_selectedIds.length} note(s)?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final idsToDelete = List<String>.from(_selectedIds);
    _exitSelectionMode();

    for (final id in idsToDelete) {
      await ApiService.deleteNote(id);
    }
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
              ],
            )
          : AppBar(
              title: const Text('My Notes'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _notes.isEmpty
          ? const Center(child: Text('No notes yet. Tap + to add one.'))
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  final id = note['_id'] as String;
                  final isSelected = _selectedIds.contains(id);

                  final isPinned = note['isPinned'] == true;

                  return Dismissible(
                    key: Key(id),
                    direction: _selectionMode
                        ? DismissDirection.none
                        : DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // swipe LEFT = pin/unpin, never actually removes the card
                        await _togglePin(note);
                        return false;
                      }
                      // swipe RIGHT = delete, ask for confirmation
                      return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete note?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (direction) => _deleteNote(id),
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: Colors.white,
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                                .withOpacity(0.15)
                          : null,
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: _selectionMode
                            ? Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              )
                            : (isPinned
                                  ? const Icon(
                                      Icons.push_pin,
                                      size: 18,
                                      color: Colors.orange,
                                    )
                                  : null),
                        title: Text(
                          note['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          note['content'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(id);
                          } else {
                            _openNoteEditor(note: note);
                          }
                        },
                        onLongPress: () {
                          if (!_selectionMode) {
                            _enterSelectionMode(id);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _selectionMode
          ? null
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  onPressed: () => _openNoteEditor(),
                  backgroundColor: Colors.orange.withOpacity(0.96),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 30),
                ),
              ),
            ),
    );
  }
}
