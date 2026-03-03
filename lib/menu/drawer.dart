import 'package:flutter/material.dart';
import 'package:ibtc/customer/ManageCustomerScreen.dart';
import 'package:ibtc/main.dart';
import 'package:ibtc/products/ManageProductScreen.dart';
import 'package:ibtc/reusable/utils.dart';

// ── Brand tokens (must match main theme) ──────────────────────────────────────
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

class IBTCDrawer extends StatelessWidget {
  const IBTCDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _DrawerHeader(),

          const SizedBox(height: 8),

          // ── Nav items ────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SectionLabel('MANAGE'),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ManageProductsScreen())),
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Customers',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ManageCustomersScreen())),
                ),
                const SizedBox(height: 8),
                _SectionLabel('DATA'),
                _DrawerItem(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Backup',
                  onTap: () async {
                    final result = await Utils.exportDatabase(context);
                    if (result != null && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)));
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.cloud_download_outlined,
                  label: 'Restore',
                  accent: _kGold,
                  onTap: () async {
                    final result = await Utils.restoreDatabase(context);
                    if (result != null && context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const MyHomePage()),
                            (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)));
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Footer version tag ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'IBTC Invoice v1.0',
              style: TextStyle(
                color: _kTextSecondary.withOpacity(0.5),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1E0A14), Color(0xff2A0F1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Stack(
        children: [
          // Decorative glow circle
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kAccent),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo mark
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimaryDim, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'IBTC',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Invoice Manager',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
    child: Text(
      text,
      style: const TextStyle(
        color: _kTextSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
  );
}

// ── Drawer Item ────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? _kTextPrimary;
    final iconBg = (accent ?? _kPrimary).withOpacity(0.12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: _kPrimary.withOpacity(0.1),
          highlightColor: _kSurface2,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: accent ?? _kAccent, size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: _kTextSecondary.withOpacity(0.4), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}