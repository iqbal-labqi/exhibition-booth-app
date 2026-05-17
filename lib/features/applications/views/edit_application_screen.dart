import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

class EditApplicationScreen extends ConsumerStatefulWidget {
  final ApplicationModel application;

  const EditApplicationScreen({super.key, required this.application});

  @override
  ConsumerState<EditApplicationScreen> createState() => _EditApplicationScreenState();
}

class _EditApplicationScreenState extends ConsumerState<EditApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _companyDescController;
  late TextEditingController _profileController;

  bool _isLoading = false;
  late List<String> _selectedAddOns;
  final List<String> _availableAddOns = ['Extra Table', 'Power Outlet', 'Spotlight', 'Wi-Fi Pro'];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with the existing application data
    _companyNameController = TextEditingController(text: widget.application.companyName);
    _companyDescController = TextEditingController(text: widget.application.companyDesc);
    _profileController = TextEditingController(text: widget.application.exhibitProfile);
    _selectedAddOns = List<String>.from(widget.application.addOns);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _updateApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updatedData = {
          'companyName': _companyNameController.text.trim(),
          'companyDesc': _companyDescController.text.trim(),
          'exhibitProfile': _profileController.text.trim(),
          'addOns': _selectedAddOns,
        };

        await ref.read(applicationRepositoryProvider).updateApplicationDetails(
          widget.application.id,
          updatedData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application Updated!'), backgroundColor: Colors.green),
          );
          context.pop(); // Go back to the history screen
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Application')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(
                  'Editing Booth: ${widget.application.boothIds.join(', ')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyDescController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Company Description', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _profileController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'What will you exhibit?', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            const Text('Add-ons (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _availableAddOns.map((addon) {
                final isSelected = _selectedAddOns.contains(addon);
                return FilterChip(
                  label: Text(addon),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _selectedAddOns.add(addon);
                      else _selectedAddOns.remove(addon);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _updateApplication,
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