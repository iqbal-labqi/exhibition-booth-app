import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/exhibition_model.dart';
import '../repositories/exhibition_repository.dart';

class EditExhibitionScreen extends ConsumerStatefulWidget {
  final ExhibitionModel exhibition;
  const EditExhibitionScreen({super.key, required this.exhibition});

  @override
  ConsumerState<EditExhibitionScreen> createState() => _EditExhibitionScreenState();
}

class _EditExhibitionScreenState extends ConsumerState<EditExhibitionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;

  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isPublished;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with the existing data
    _titleController = TextEditingController(text: widget.exhibition.title);
    _descController = TextEditingController(text: widget.exhibition.description);
    _imageUrlController = TextEditingController(text: widget.exhibition.imageUrl);
    _startDate = widget.exhibition.startDate;
    _endDate = widget.exhibition.endDate;
    _isPublished = widget.exhibition.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _updateExhibition() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updatedData = {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'imageUrl': _imageUrlController.text.trim(),
          'startDate': _startDate.toIso8601String(),
          'endDate': _endDate.toIso8601String(),
          'isPublished': _isPublished,
        };

        await ref.read(exhibitionRepositoryProvider).updateExhibition(widget.exhibition.id, updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exhibition Updated!'), backgroundColor: Colors.green),
          );
          context.pop(); // Go back to dashboard
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Exhibition')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Exhibition Title', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter a description' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Banner Image URL', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateFormat.format(_startDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateFormat.format(_endDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publish Exhibition'),
              subtitle: const Text('Make this visible to guests and exhibitors'),
              value: _isPublished,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => _isPublished = val),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _updateExhibition,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}