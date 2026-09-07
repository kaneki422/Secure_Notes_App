import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;

  // Color _backgroundColor = Colors.black;

  // final List<Color> _colorOptions = [
  //   Colors.black,
  //   Colors.white,
  //   Colors.red.shade100,
  //   Colors.orange.shade100,
  //   Colors.yellow.shade100,
  //   Colors.green.shade100,
  //   Colors.blue.shade100,
  //   Colors.purple.shade100,
  //   Colors.grey.shade300,
  // ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?['title'] ?? '');
    _contentController = TextEditingController(
      text: widget.note?['content'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // void _showColorPicker() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return Padding(
  //         padding: const EdgeInsets.all(20.0),
  //         child: Wrap(
  //           spacing: 16,
  //           runSpacing: 16,
  //           children: _colorOptions.map((color) {
  //             return GestureDetector(
  //               onTap: () {
  //                 setState(() => _backgroundColor = color);
  //                 Navigator.pop(context);
  //               },
  //               child: Container(
  //                 width: 48,
  //                 height: 48,
  //                 decoration: BoxDecoration(
  //                   color: color,
  //                   shape: BoxShape.circle,
  //                   border: Border.all(
  //                     color: _backgroundColor == color
  //                         ? Colors.black
  //                         : Colors.grey,
  //                     width: _backgroundColor == color ? 3 : 1,
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.note == null) {
        await ApiService.createNote(
          title.isEmpty ? 'Untitled' : title,
          content,
        );
      } else {
        await ApiService.updateNote(
          widget.note!['_id'],
          title.isEmpty ? 'Untitled' : title,
          content,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime displayDate =
        widget.note != null && widget.note!['createdAt'] != null
        ? DateTime.parse(widget.note!['createdAt'])
        : DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy | HH:mm')
        .format(displayDate);
    final charCount = _contentController.text.length;

    return Scaffold(
      // backgroundColor: _backgroundColor,
      appBar: AppBar(
        // backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : _saveNote,
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.palette_outlined),
          //   onPressed: _showColorPicker,
          // ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'share') {
                // we'll wire this up next
              } else if (value == 'delete') {
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete note?'),
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

                if (confirmed && widget.note != null) {
                  try {
                    await ApiService.deleteNote(widget.note!['_id']);
                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } 
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 4),
            Text(
              '$formattedDate | $charCount characters',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (charCount > 0) const Divider(height: 24),
            Expanded(
              child: TextField(
                controller: _contentController,
                autofocus: widget.note == null,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Start typing',
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
