import 'package:flutter/material.dart';
import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/DbTables/product-item-table.dart';
import 'package:ibtc/main.dart';
import 'package:ibtc/service.dart';

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
const _kOrange        = Color(0xffE87C30);

class TemplatesPage extends StatefulWidget {
  final Invoice data;
  final List<ProductItem> productList;

  const TemplatesPage({
    super.key,
    required this.data,
    required this.productList,
  });

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  bool _loading = false;
  TemplateType? _generating;

  Future<void> _onTemplateSelect(TemplateType type) async {
    if (_loading) return;
    setState(() { _loading = true; _generating = type; });
    await Service.generateInvoice(widget.data, widget.productList, type);
    if (mounted) {
      setState(() { _loading = false; _generating = null; });
      // Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(6, 8, 16, 20),
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
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPrimaryDim, _kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined,
                        color: Colors.white70, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Template',
                            style: TextStyle(
                                color: _kTextPrimary, fontSize: 18,
                                fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        Text(
                          '${widget.data.invoiceNumber ?? ''} · ${widget.data.customerName ?? ''}',
                          style: const TextStyle(
                              color: _kTextSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Instruction label ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'CHOOSE A FORMAT',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // ── Template cards ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _TemplateCard(
                      title: 'IBTC Template',
                      subtitle: 'Classic blue-accented invoice layout',
                      icon: Icons.receipt_long_outlined,
                      accentColor: const Color(0xff5B8CFF),
                      patternIcon: Icons.receipt_long,
                      isGenerating: _generating == TemplateType.ibtc,
                      onTap: () => _onTemplateSelect(TemplateType.ibtc),
                    ),
                    const SizedBox(height: 14),
                    _TemplateCard(
                      title: 'Oman Trading Template',
                      subtitle: 'Warm orange-accented invoice layout',
                      icon: Icons.description_outlined,
                      accentColor: _kOrange,
                      patternIcon: Icons.description,
                      isGenerating: _generating == TemplateType.omanTrading,
                      onTap: () => _onTemplateSelect(TemplateType.omanTrading),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Template Card ──────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData patternIcon;
  final Color accentColor;
  final bool isGenerating;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.patternIcon,
    required this.accentColor,
    required this.isGenerating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGenerating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isGenerating
                ? accentColor.withOpacity(0.6)
                : _kBorder,
            width: isGenerating ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Decorative background pattern
              Positioned(
                right: -20,
                top: -20,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(patternIcon,
                      size: 120, color: accentColor),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: accentColor.withOpacity(0.25)),
                      ),
                      child: isGenerating
                          ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: accentColor, strokeWidth: 2),
                      )
                          : Icon(icon, color: accentColor, size: 26),
                    ),
                    const SizedBox(width: 16),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                color: _kTextPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: const TextStyle(
                                  color: _kTextSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          // Download pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: accentColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    isGenerating
                                        ? Icons.hourglass_top_rounded
                                        : Icons.download_rounded,
                                    color: accentColor, size: 12),
                                const SizedBox(width: 5),
                                Text(
                                  isGenerating ? 'Generating…' : 'Generate PDF',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    if (!isGenerating)
                      Icon(Icons.chevron_right,
                          color: _kTextSecondary.withOpacity(0.4), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}