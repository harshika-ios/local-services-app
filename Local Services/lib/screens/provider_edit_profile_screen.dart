import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../widgets/avatar_picker.dart';

class _EditData {
  const _EditData({required this.provider, required this.categories});
  final ProviderModel provider;
  final List<CategoryModel> categories;
}

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  late Future<_EditData?> _future;
  String? _serviceType;
  File? _pickedFile;
  String? _existingAvatarUrl;
  String? _providerId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<_EditData?> _load() async {
    final results = await Future.wait([
      ProfileService.instance.fetchMyProvider(),
      SupabaseService.instance.fetchCategories(),
    ]);
    final provider = results[0] as ProviderModel?;
    final categories = results[1] as List<CategoryModel>;
    if (provider == null) return null;

    _nameController.text = provider.name;
    _phoneController.text = provider.phone;
    _addressController.text = provider.address ?? '';
    _descController.text = provider.description ?? '';
    _serviceType = provider.serviceType;
    _existingAvatarUrl = provider.avatarUrl;
    _providerId = provider.id;

    return _EditData(provider: provider, categories: categories);
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _pickedFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final providerId = _providerId;
    if (providerId == null) {
      setState(() => _error = 'No provider profile to update.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? avatarUrl;
      if (_pickedFile != null) {
        avatarUrl = await ProfileService.instance.uploadAvatar(_pickedFile!);
      }
      await ProfileService.instance.updateMyProvider(
        providerId: providerId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        serviceType: _serviceType,
        address: _addressController.text.trim(),
        description: _descController.text.trim(),
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: FutureBuilder<_EditData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No provider listing found.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AvatarPicker(
                      file: _pickedFile,
                      networkUrl: _existingAvatarUrl,
                      onTap: _saving ? null : _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _LabeledField(
                    label: 'Name',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _decoration(hint: 'e.g. Raj Electrician'),
                      validator: _required,
                    ),
                  ),
                  _LabeledField(
                    label: 'Phone',
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration(hint: '+91 98xxx xxxxx'),
                      validator: _required,
                    ),
                  ),
                  _LabeledField(
                    label: 'Service type',
                    child: DropdownButtonFormField<String>(
                      initialValue: _serviceType,
                      decoration: _decoration(hint: 'Select a service'),
                      items: data.categories
                          .map((c) => DropdownMenuItem(
                                value: c.displayName,
                                child: Text(c.displayName),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _serviceType = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Pick a service' : null,
                    ),
                  ),
                  _LabeledField(
                    label: 'Address',
                    child: TextFormField(
                      controller: _addressController,
                      decoration: _decoration(hint: 'Sector 18, Noida'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Description',
                    child: TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: _decoration(
                        hint: 'Tell users what you offer',
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _decoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.2,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
