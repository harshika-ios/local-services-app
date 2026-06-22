import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../services/profile_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({required this.onChosen, super.key});

  final VoidCallback onChosen;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _pick(UserRole role) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProfileService.instance.setRole(role);
      if (!mounted) return;
      widget.onChosen();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.waving_hand, color: primary, size: 30),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'How will you use the app?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You can change this later from your profile.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  _RoleCard(
                    icon: Icons.search,
                    iconBgColor: const Color(0xFFE8F0FF),
                    iconColor: const Color(0xFF1A4FCC),
                    title: 'Continue as User',
                    subtitle: 'Find and contact local service providers near you.',
                    onTap: _busy ? null : () => _pick(UserRole.user),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.handyman_outlined,
                    iconBgColor: const Color(0xFFE7F8EF),
                    iconColor: const Color(0xFF1F7A3D),
                    title: 'Register as Service Provider',
                    subtitle: 'List your services and get discovered by nearby users.',
                    onTap: _busy ? null : () => _pick(UserRole.provider),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBgColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconBgColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final effectiveBgColor = iconBgColor ?? const Color(0xFFE8F0FF);
    final effectiveIconColor = iconColor ?? primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: effectiveBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: effectiveIconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
