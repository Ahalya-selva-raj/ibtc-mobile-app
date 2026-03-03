import 'package:flutter/material.dart';
import 'package:ibtc/customer/CustomerModel.dart';
import 'package:ibtc/db-helper.dart';
import 'package:ibtc/reusable/manage-shared-widget.dart';

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

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({Key? key}) : super(key: key);

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  final db = DatabaseHelper.instance;
  List<Customer> _customers = [];
  List<Customer> _filtered  = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  // Avatar accent colors — cycles per row
  static const _avatarColors = [
    _kAccent,
    _kGold,
    Color(0xff5B8CFF),
    Color(0xff3ECFB2),
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final customers = await db.getCustomers();
    setState(() {
      _customers = customers;
      _filtered  = customers;
      _loading   = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _customers
          : _customers
          .where((c) =>
      (c.name ?? '').toLowerCase().contains(q) ||
          (c.address ?? '').toLowerCase().contains(q))
          .toList();
    });
  }

  // ── bottom sheet form ──────────────────────────────────────────────────────

  void _openForm({Customer? existing}) {
    final nameCtrl    = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormSheet(
        title: existing == null ? 'Add Customer' : 'Edit Customer',
        formKey: formKey,
        fields: [
          SheetField(
            controller: nameCtrl,
            label: 'Customer Name',
            icon: Icons.person_outline,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Name required' : null,
          ),
          const SizedBox(height: 10),
          SheetField(
            controller: addressCtrl,
            label: 'Customer Address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Address required' : null,
          ),
        ],
        buttonLabel: existing == null ? 'Add Customer' : 'Save Changes',
        onConfirm: () async {
          if (formKey.currentState?.validate() != true) return;
          final customer = Customer(
            id: existing?.id,
            name: nameCtrl.text.trim(),
            address: addressCtrl.text.trim(),
          );
          if (existing == null) {
            await db.insertCustomer(customer);
          } else {
            await db.updateCustomer(customer);
          }
          Navigator.pop(ctx);
          _loadCustomers();
        },
      ),
    );
  }

  // ── delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await showDeleteDialog(
        context, 'Delete Customer', 'Delete "${customer.name}"?');
    if (confirmed == true) {
      await db.deleteCustomer(customer.id!);
      _loadCustomers();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            ScreenHeader(
              title: 'Customers',
              subtitle: '${_customers.length} saved',
              icon: Icons.people_outline,
              onAdd: () => _openForm(),
            ),

            // ── Search ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ManageSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search by name or address…'),
            ),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2))
                  : _filtered.isEmpty
                  ? EmptyState(
                icon: Icons.people_outline,
                message: _searchCtrl.text.isEmpty
                    ? 'No customers yet'
                    : 'No results for "${_searchCtrl.text}"',
                sub: _searchCtrl.text.isEmpty
                    ? 'Tap + to add your first customer'
                    : 'Try a different search term',
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final c = _filtered[i];
                  final color =
                  _avatarColors[i % _avatarColors.length];
                  final initials = (c.name ?? '?')
                      .trim()
                      .split(' ')
                      .take(2)
                      .map((w) =>
                  w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join();
                  return _CustomerRow(
                    customer: c,
                    initials: initials,
                    avatarColor: color,
                    onEdit: () => _openForm(existing: c),
                    onDelete: () => _confirmDelete(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer Row ───────────────────────────────────────────────────────────────

class _CustomerRow extends StatelessWidget {
  final Customer customer;
  final String initials;
  final Color avatarColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerRow({
    required this.customer,
    required this.initials,
    required this.avatarColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          // Avatar
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
          // Name + address
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name ?? '—',
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer.address ?? '—',
                    style: const TextStyle(
                        color: _kTextSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionBtn(
                    icon: Icons.edit_outlined,
                    color: _kTextSecondary,
                    onTap: onEdit),
                ActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.redAccent,
                    onTap: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}