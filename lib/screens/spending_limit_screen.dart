import 'package:flutter/material.dart';
import '../services/spending_limit_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class SpendingLimitScreen extends StatefulWidget {
  const SpendingLimitScreen({super.key});

  @override
  State<SpendingLimitScreen> createState() => _SpendingLimitScreenState();
}

class _SpendingLimitScreenState extends State<SpendingLimitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  final _authService = AuthService();
  SpendingPeriod _selectedPeriod = SpendingPeriod.month;
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final settings = await SpendingLimitService.getSpendingLimitSettings(userId);
    
    if (mounted) {
      setState(() {
        _isEnabled = settings['enabled'] as bool;
        _selectedPeriod = settings['period'] as SpendingPeriod? ?? SpendingPeriod.month;
        final limit = settings['limit'] as double?;
        if (limit != null) {
          _limitController.text = limit.toStringAsFixed(2);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid spending limit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await SpendingLimitService.saveSpendingLimit(
      userId: userId,
      limit: limit,
      period: _selectedPeriod,
      enabled: _isEnabled,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnabled 
            ? 'Spending limit saved successfully!' 
            : 'Spending limit disabled'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Limit'),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enable/Disable Toggle
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        value: _isEnabled,
                        onChanged: (value) {
                          setState(() => _isEnabled = value);
                        },
                        title: const Text(
                          'Enable Spending Limit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Get notified when you approach or exceed your limit',
                        ),
                        activeColor: Constants.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Limit Amount Input
                    if (_isEnabled) ...[
                      const Text(
                        'Spending Limit Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _limitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₱ ',
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a spending limit';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      // Period Selection
                      const Text(
                        'Limit Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<SpendingPeriod>(
                              title: const Text('Per Day'),
                              value: SpendingPeriod.day,
                              groupValue: _selectedPeriod,
                              onChanged: (value) {
                                setState(() => _selectedPeriod = value!);
                              },
                              activeColor: Constants.primaryBlue,
                            ),
                            const Divider(height: 1),
                            RadioListTile<SpendingPeriod>(
                              title: const Text('Per Week'),
                              value: SpendingPeriod.week,
                              groupValue: _selectedPeriod,
                              onChanged: (value) {
                                setState(() => _selectedPeriod = value!);
                              },
                              activeColor: Constants.primaryBlue,
                            ),
                            const Divider(height: 1),
                            RadioListTile<SpendingPeriod>(
                              title: const Text('Per Month'),
                              value: SpendingPeriod.month,
                              groupValue: _selectedPeriod,
                              onChanged: (value) {
                                setState(() => _selectedPeriod = value!);
                              },
                              activeColor: Constants.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

