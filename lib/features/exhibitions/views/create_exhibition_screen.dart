import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../authentication/providers/auth_provider.dart';
import '../models/exhibition_model.dart';
import '../repositories/exhibition_repository.dart';

class CreateExhibitionScreen extends ConsumerStatefulWidget {
  const CreateExhibitionScreen({super.key});

  @override
  ConsumerState<CreateExhibitionScreen> createState() => _CreateExhibitionScreenState();
}

class _CreateExhibitionScreenState extends ConsumerState<CreateExhibitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublished = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      setState(() => _isLoading = true);

      try {
        final user = ref.read(currentUserProvider); // ADD THIS
        final newExhibition = ExhibitionModel(
          id: '', // Firestore auto-generates this
          organizerId: user!.uid, // REPLACE 'current_user_id' WITH THIS
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isPublished: _isPublished,
        );

        await ref.read(exhibitionRepositoryProvider).createExhibition(newExhibition);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exhibition Created!'), backgroundColor: Colors.green),
          );
          context.pop(); // Go back to dashboard
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Create Exhibition')),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate == null ? 'Start Date' : dateFormat.format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate == null ? 'End Date' : dateFormat.format(_endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publish Immediately'),
              subtitle: const Text('Guests can see this on the home screen'),
              value: _isPublished,
              onChanged: (val) => setState(() => _isPublished = val),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submitForm,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Exhibition', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}