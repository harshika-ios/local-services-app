import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({required this.onSubmitted, super.key});

  final VoidCallback onSubmitted;

  @override
  State<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  String? _serviceType;
  double? _latitude;
  double? _longitude;
  String? _placeName;
  File? _avatarFile;
  bool _capturingLocation = false;
  bool _submitting = false;
  String? _error;

  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = SupabaseService.instance.fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _captureLocation() async {
    setState(() {
      _capturingLocation = true;
      _placeName = null;
      _error = null;
    });
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        setState(() => _error =
            'Could not read your location. Enable location and try again.');
        return;
      }
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });

      final place = await LocationService.instance
          .reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _placeName = place);
    } finally {
      if (mounted) setState(() => _capturingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Capture your location before continuing.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await ProfileService.instance.uploadAvatar(_avatarFile!);
      }
      await ProfileService.instance.createMyProvider(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        serviceType: _serviceType!,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your listing'),
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
      body: FutureBuilder<List<CategoryModel>>(
        future: _categoriesFuture,
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
          final categories = snapshot.data ?? const <CategoryModel>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _AvatarPicker(
                      file: _avatarFile,
                      onTap: _submitting ? null : _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                      items: categories
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
                    label: 'Address (optional)',
                    child: TextFormField(
                      controller: _addressController,
                      decoration: _decoration(hint: 'Sector 18, Noida'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Location',
                    child: _LocationRow(
                      latitude: _latitude,
                      longitude: _longitude,
                      placeName: _placeName,
                      busy: _capturingLocation,
                      onTap: _capturingLocation ? null : _captureLocation,
                    ),
                  ),
                  _LabeledField(
                    label: 'Description (optional)',
                    child: TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: _decoration(
                        hint: 'Tell users what you offer',
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save & continue',
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

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

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

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.busy,
    required this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final String? placeName;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasCoords = latitude != null && longitude != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              hasCoords ? Icons.check_circle : Icons.my_location,
              color: hasCoords ? Colors.green : primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busy
                        ? 'Reading location…'
                        : hasCoords
                            ? (placeName ?? 'Location captured')
                            : 'Use my current location',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasCoords ? Colors.black87 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasCoords && !busy) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.file, required this.onTap});

  final File? file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              shape: BoxShape.circle,
              image: file != null
                  ? DecorationImage(
                      image: FileImage(file!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: file == null
                ? Icon(Icons.person_outline, color: primary, size: 44)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
