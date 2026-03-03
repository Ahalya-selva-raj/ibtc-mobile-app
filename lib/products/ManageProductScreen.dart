import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ibtc/db-helper.dart';
import 'package:ibtc/products/CatalogProductModel.dart';
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

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final db = DatabaseHelper.instance;
  List<CatalogProduct> _products = [];
  List<CatalogProduct> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await db.getCatalogProducts();
    setState(() {
      _products = products;
      _filtered  = products;
      _loading   = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _products
          : _products
          .where((p) => (p.name ?? '').toLowerCase().contains(q))
          .toList();
    });
  }

  // ── bottom sheet form ──────────────────────────────────────────────────────

  void _openForm({CatalogProduct? existing}) {
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing?.defaultPrice?.toStringAsFixed(2) ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormSheet(
        title: existing == null ? 'Add Product' : 'Edit Product',
        formKey: formKey,
        fields: [
          SheetField(
            controller: nameCtrl,
            label: 'Product Name',
            icon: Icons.label_outline,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Name required' : null,
          ),
          const SizedBox(height: 10),
          SheetField(
            controller: priceCtrl,
            label: 'Default Unit Price',
            icon: Icons.attach_money,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Price required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            },
          ),
        ],
        buttonLabel: existing == null ? 'Add Product' : 'Save Changes',
        onConfirm: () async {
          if (formKey.currentState?.validate() != true) return;
          final product = CatalogProduct(
            id: existing?.id,
            name: nameCtrl.text.trim(),
            defaultPrice: double.parse(priceCtrl.text.trim()),
          );
          if (existing == null) {
            await db.insertCatalogProduct(product);
          } else {
            await db.updateCatalogProduct(product);
          }
          Navigator.pop(ctx);
          _loadProducts();
        },
      ),
    );
  }

  // ── delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(CatalogProduct product) async {
    final confirmed = await showDeleteDialog(
        context, 'Delete Product', 'Delete "${product.name}"?');
    if (confirmed == true) {
      await db.deleteCatalogProduct(product.id!);
      _loadProducts();
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
              title: 'Products',
              subtitle: '${_products.length} in catalog',
              icon: Icons.inventory_2_outlined,
              onAdd: () => _openForm(),
            ),

            // ── Search ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ManageSearchBar(controller: _searchCtrl, hint: 'Search products…'),
            ),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2))
                  : _filtered.isEmpty
                  ? EmptyState(
                icon: Icons.inventory_2_outlined,
                message: _searchCtrl.text.isEmpty
                    ? 'No products yet'
                    : 'No results for "${_searchCtrl.text}"',
                sub: _searchCtrl.text.isEmpty
                    ? 'Tap + to add your first product'
                    : 'Try a different search term',
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) => _ProductRow(
                  product: _filtered[i],
                  index: i,
                  onEdit: () => _openForm(existing: _filtered[i]),
                  onDelete: () => _confirmDelete(_filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Row ────────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final CatalogProduct product;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.index,
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
            height: 64,
            decoration: const BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          // Index badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    color: _kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Name + price
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '—',
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
                    'Default: ${product.defaultPrice?.toStringAsFixed(2) ?? '—'}',
                    style: const TextStyle(
                        color: _kTextSecondary, fontSize: 12),
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