import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kPrimary       = Color(0xff941751);
const _kPrimaryDim    = Color(0xff6b1039);
const _kAccent        = Color(0xffE8306A);
const _kBg            = Color(0xff0F0F13);
const _kSurface       = Color(0xff1A1A22);
const _kSurface2      = Color(0xff22222E);
const _kBorder        = Color(0xff2E2E3E);
const _kTextPrimary   = Color(0xffF0EEF6);
const _kTextSecondary = Color(0xff8A889A);
const _kGold          = Color(0xffD4A853);

// ── Screen Header ──────────────────────────────────────────────────────────────

class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onAdd;

  const ScreenHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1E0A14), _kBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: _kTextPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimaryDim, _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                        color: _kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Add button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────────

class ManageSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const ManageSearchBar({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: _kAccent,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
        prefixIcon:
        const Icon(Icons.search, color: _kTextSecondary, size: 18),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
            onTap: () => controller.clear(),
            child: const Icon(Icons.close,
                color: _kTextSecondary, size: 16))
            : null,
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kAccent, width: 1.5)),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}

// ── Form Sheet ─────────────────────────────────────────────────────────────────

class FormSheet extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final String buttonLabel;
  final VoidCallback onConfirm;

  const FormSheet({
    required this.title,
    required this.formKey,
    required this.fields,
    required this.buttonLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 16),
            // Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: fields),
            ),
            const SizedBox(height: 20),
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(buttonLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.2)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Sheet Field ────────────────────────────────────────────────────────────────

class SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    validator: validator,
    maxLines: maxLines,
    cursorColor: _kAccent,
    style: const TextStyle(
        color: _kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(color: _kTextSecondary, fontSize: 12),
      prefixIcon: Icon(icon, color: _kTextSecondary, size: 17),
      filled: true,
      fillColor: _kSurface2,
      errorStyle: const TextStyle(color: _kAccent, fontSize: 11),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _kAccent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Colors.redAccent, width: 1.5)),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    ),
  );
}

// ── Action Button ──────────────────────────────────────────────────────────────

class ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

// ── Empty State ────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPrimary.withOpacity(0.2)),
          ),
          child: Icon(icon, color: _kPrimary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(sub,
            style: const TextStyle(
                color: _kTextSecondary, fontSize: 13)),
      ],
    ),
  );
}

// ── Delete Dialog helper ───────────────────────────────────────────────────────

Future<bool?> showDeleteDialog(
    BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder)),
      title: Text(title,
          style: const TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700)),
      content: Text(message,
          style: const TextStyle(color: _kTextSecondary, fontSize: 13)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}