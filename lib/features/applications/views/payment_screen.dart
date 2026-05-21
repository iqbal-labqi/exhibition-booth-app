import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/application_repository.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String applicationId;
  final double amount; // <--- 1. ADD THIS

  const PaymentScreen({
    super.key,
    required this.applicationId,
    required this.amount, // <--- 2. ADD THIS
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate a 2-second network delay for realism
      await Future.delayed(const Duration(seconds: 2));

      try {
        await ref.read(applicationRepositoryProvider).processPayment(widget.applicationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green),
          );
          // Go back to the history screen so they can see their new 'PAID' status!
          context.go('/history');
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
      appBar: AppBar(title: const Text('Secure Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Icon(Icons.credit_card, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            // Mock price for demonstration
            Center(
              child: Text(
                'RM ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            TextFormField(
              decoration: const InputDecoration(labelText: 'Cardholder Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              validator: (v) => v!.isEmpty ? 'Enter name on card' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Card Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers)),
              validator: (v) => v!.length < 16 ? 'Enter a valid 16-digit card number' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Expiry (MM/YY)', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()),
                    validator: (v) => v!.length < 3 ? 'Invalid CVV' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            FilledButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade600,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Payment', style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}