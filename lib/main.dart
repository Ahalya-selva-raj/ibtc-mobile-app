import 'package:flutter/material.dart';
import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/db-helper.dart';
import 'package:ibtc/menu/drawer.dart';
import 'package:ibtc/new-invoice.dart';
import 'package:ibtc/service.dart';
import 'package:ibtc/templates.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahalio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _kBg,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final db = DatabaseHelper.instance;
  List<Invoice>? invoices;

  // ✅ Initialized inline — never uninitialized even on hot reload
  late final AnimationController _fabAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    _fabAnim.forward();
    getInvoices();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  void getInvoices() async {
    final result = await db.getInvoices();
    if (mounted) setState(() => invoices = result);
  }

  double get _totalRevenue =>
      invoices?.fold(0.0, (s, e) => s! + (e.totalAmount ?? 0)) ?? 0;

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      drawer: const IBTCDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top nav bar ────────────────────────────────────────────────────
            _TopBar(),

            // ── Summary hero card ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _HeroCard(
                invoiceCount: invoices?.length ?? 0,
                totalRevenue: _totalRevenue,
              ),
            ),

            // ── Section label ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ALL INVOICES',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (invoices != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kSurface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Text(
                        '${invoices!.length}',
                        style: const TextStyle(
                            color: _kTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // ── Invoice list ───────────────────────────────────────────────────
            Expanded(
              child: invoices == null
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2))
                  : invoices!.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: invoices!.length,
                itemBuilder: (ctx, i) => _InvoiceRow(
                  invoice: invoices![i],
                  index: i,
                  onMenuTap: (pos) =>
                      _showPopUpMenu(pos, data: invoices![i]),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
            parent: _fabAnim, curve: Curves.easeOutBack),
        child: FloatingActionButton(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 10,
          onPressed: () async {
            final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewInvoice()));
            if (result == true) getInvoices();
          },
          child: const Icon(Icons.add_rounded, size: 26),
        ),
      ),
    );
  }

  // ── popup menu ────────────────────────────────────────────────────────────────

  _showPopUpMenu(Offset offset, {required Invoice data}) async {
    final size  = MediaQuery.of(context).size;
    await showMenu<MenuItemType>(
      context: context,
      color: _kSurface2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _kBorder)),
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy,
          size.width - offset.dx, size.height - offset.dy),
      items: MenuItemType.values
          .map((t) => PopupMenuItem<MenuItemType>(
        value: t,
        child: Row(
          children: [
            Icon(_menuIcon(t), color: _menuColor(t), size: 17),
            const SizedBox(width: 10),
            Text(
              getMenuItemString(t),
              style: TextStyle(
                  color: t == MenuItemType.delete
                      ? Colors.redAccent
                      : _kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ))
          .toList(),
    ).then((item) async {
      if (item == null) return;
      switch (item) {
        case MenuItemType.delete:
          await _confirmDelete(data);
          break;
        case MenuItemType.edit:
          if (data.id != null) {
            final inv  = await db.getInvoiceByInvoiceId(data.id!);
            final prod = await db.getItemsByInvoiceId(data.id!);
            if (!mounted) return;
            final r = await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    NewInvoice(invoice: inv, productItems: prod)));
            if (r == true) getInvoices();
          }
          break;
        case MenuItemType.clone:
          await _cloneInvoice(data);
          break;
        case MenuItemType.download:
          final prod = await db.getItemsByInvoiceId(data.id!);
          if (!mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  TemplatesPage(data: data, productList: prod)));
          break;
      }
    });
  }

  Future<void> _confirmDelete(Invoice data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _kBorder)),
        title: const Text('Delete Invoice',
            style: TextStyle(
                color: _kTextPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete ${data.invoiceNumber} for ${data.customerName}?\nThis cannot be undone.',
          style:
          const TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
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
    if (confirmed == true && data.id != null) {
      await db.deleteInvoice(data.id!);
      setState(() => invoices?.removeWhere((e) => e.id == data.id));
    }
  }

  Future<void> _cloneInvoice(Invoice data) async {
    final productList = await db.getItemsByInvoiceId(data.id!);
    final invoice = Invoice(
        id: null,
        invoiceNumber: await db.generateInvoiceNumber(),
        date: data.date,
        customerName: data.customerName,
        customerAddress: data.customerAddress,
        totalAmount: data.totalAmount);
    final invoiceId = await db.insertInvoice(invoice);
    for (final item in productList) {
      item.invoiceId = invoiceId;
      item.id = null;
      await db.insertProductItem(item);
    }
    getInvoices();
  }

  IconData _menuIcon(MenuItemType t) {
    switch (t) {
      case MenuItemType.edit:     return Icons.edit_outlined;
      case MenuItemType.delete:   return Icons.delete_outline;
      case MenuItemType.clone:    return Icons.copy_outlined;
      case MenuItemType.download: return Icons.download_outlined;
    }
  }

  Color _menuColor(MenuItemType t) =>
      t == MenuItemType.delete ? Colors.redAccent : _kTextSecondary;
}

// ── Top Bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: _kTextPrimary, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Invoice Generator',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Subtle logo mark
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimaryDim, _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long,
                color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Hero Summary Card ──────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final int invoiceCount;
  final double totalRevenue;

  const _HeroCard(
      {required this.invoiceCount, required this.totalRevenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1E0A14), Color(0xff2A0F1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kAccent),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL REVENUE',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                NumberFormat.currency(symbol: '', decimalDigits: 2)
                    .format(totalRevenue),
                style: const TextStyle(
                  color: _kGold,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              // Divider line
              Container(
                  height: 1,
                  color: _kPrimary.withOpacity(0.25)),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _MiniStat(
                    label: 'Invoices',
                    value: '$invoiceCount',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 32, color: _kBorder),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'This month',
                    value: DateFormat('MMM yyyy').format(DateTime.now()),
                    icon: Icons.calendar_today_outlined,
                    isText: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isText;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kTextSecondary, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isText ? _kTextSecondary : _kTextPrimary,
                fontSize: isText ? 12 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label,
                style: const TextStyle(
                    color: _kTextSecondary, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ── Invoice Row ────────────────────────────────────────────────────────────────

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final int index;
  final void Function(Offset) onMenuTap;

  const _InvoiceRow({
    required this.invoice,
    required this.index,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = (invoice.customerName ?? '?')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final dateStr = _formatDate(invoice.date);

    // Cycle through accent colors for avatars
    final avatarColors = [
      _kAccent, _kGold, const Color(0xff5B8CFF), const Color(0xff3ECFB2)
    ];
    final avatarColor = avatarColors[index % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // ── Left accent bar ────────────────────────────────────────────────
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),

          // ── Avatar ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor.withOpacity(0.12),
              child: Text(
                initials,
                style: TextStyle(
                  color: avatarColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // ── Customer name + date ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.customerName ?? '—',
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Invoice number pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          invoice.invoiceNumber ?? '—',
                          style: const TextStyle(
                              color: _kAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            color: _kTextSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Amount + menu ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (invoice.totalAmount ?? 0).toStringAsFixed(2),
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTapDown: (d) => onMenuTap(d.globalPosition),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kSurface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Icon(Icons.more_horiz,
                        color: _kTextSecondary, size: 15),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _kPrimary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: _kPrimary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'No invoices yet',
            style: TextStyle(
                color: _kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create your first invoice',
            style:
            TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Enums & helpers ────────────────────────────────────────────────────────────

enum MenuItemType { edit, delete, clone, download }
enum TemplateType { ibtc, omanTrading }

String getMenuItemString(MenuItemType t) {
  switch (t) {
    case MenuItemType.edit:     return 'Edit';
    case MenuItemType.delete:   return 'Delete';
    case MenuItemType.clone:    return 'Clone';
    case MenuItemType.download: return 'Download';
  }
}