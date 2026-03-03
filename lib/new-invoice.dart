import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/customer/CustomerModel.dart';
import 'package:ibtc/db-helper.dart';
import 'package:ibtc/products/CatalogProductModel.dart';
import 'package:ibtc/reusable/widgets.dart';
import 'package:intl/intl.dart';

import 'DbTables/product-item-table.dart';

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

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

class NewInvoice extends StatefulWidget {
  final Invoice? invoice;
  final List<ProductItem>? productItems;
  const NewInvoice({Key? key, this.invoice, this.productItems}) : super(key: key);

  @override
  State<NewInvoice> createState() => _NewInvoiceState();
}

class _NewInvoiceState extends State<NewInvoice> with SingleTickerProviderStateMixin {
  final db = DatabaseHelper.instance;

  List<ProductItem> productItem = [];
  int? productIndexToBeUpdated;
  DateTime? pickedInvoiceDate;

  final customerName    = TextEditingController();
  final customerAddress = TextEditingController();
  final invoiceDate     = TextEditingController();
  final invoiceNumber   = TextEditingController();
  final description     = TextEditingController();
  final quantity        = TextEditingController();
  final unitPrice       = TextEditingController();

  final _customerFormKey          = GlobalKey<FormState>();
  final _productFormKey           = GlobalKey<FormState>();
  final _suggestionsBoxController = SuggestionsBoxController();

  // inline init — never uninitialized
  late final AnimationController _fabAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));

  List<int> deletedProductIds = [];

  @override
  void initState() {
    super.initState();
    _fabAnim.forward();
    if (widget.invoice != null) {
      invoiceNumber.text   = widget.invoice?.invoiceNumber ?? '';
      customerName.text    = widget.invoice?.customerName ?? '';
      customerAddress.text = widget.invoice?.customerAddress ?? '';
      invoiceDate.text     = DateFormat('dd/MM/yyyy').format(
          DateTime.parse(widget.invoice?.date ?? DateTime.now().toIso8601String()));
    }
    if (widget.productItems?.isNotEmpty == true) {
      productItem = List.from(widget.productItems!);
    }
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    for (final c in [customerName, customerAddress, invoiceDate, invoiceNumber,
      description, quantity, unitPrice]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _grandTotal =>
      productItem.fold(0, (s, i) => s + (i.quantity ?? 0) * (i.price ?? 0));

  Future<List<Customer>> _searchCustomers(String q) async {
    final all = await db.getCustomers();
    if (q.isEmpty) return all;
    return all.where((c) =>
        (c.name ?? '').toLowerCase().contains(q.toLowerCase())).toList();
  }

  Future<void> _datePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 30),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _kAccent, onPrimary: Colors.white,
              surface: _kSurface, onSurface: _kTextPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() {
      invoiceDate.text  = DateFormat('dd/MM/yyyy').format(picked);
      pickedInvoiceDate = picked;
    });
  }

  Future<void> _saveInvoice() async {
    if (!(_customerFormKey.currentState?.validate() ?? false)) return;
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const _LoadingDialog());

    final name    = customerName.text.trim();
    final address = customerAddress.text.trim();
    final existing = await _searchCustomers(name);
    if (!existing.any((c) => c.name?.toLowerCase() == name.toLowerCase())) {
      await db.insertCustomer(Customer(name: name, address: address));
    }
    if (deletedProductIds.isNotEmpty) await db.deleteProduct(deletedProductIds);

    final invoice = Invoice(
      id: widget.invoice?.id,
      invoiceNumber: invoiceNumber.text.isEmpty
          ? await db.generateInvoiceNumber() : invoiceNumber.text,
      date: pickedInvoiceDate == null
          ? (widget.invoice?.date ?? DateTime.now().toIso8601String())
          : pickedInvoiceDate!.toIso8601String(),
      customerName: name, customerAddress: address, totalAmount: _grandTotal,
    );

    final invoiceId = invoice.id == null
        ? await db.insertInvoice(invoice) : await db.editInvoice(invoice);

    for (final item in productItem) {
      item.invoiceId = widget.invoice?.id ?? invoiceId;
      if (widget.invoice?.id != null) {
        final r = await db.editProductItem(item);
        if (r == 0) await db.insertProductItem(item);
      } else {
        await db.insertProductItem(item);
      }
    }
    Navigator.of(context).pop(true);
    Navigator.of(context).pop(true);
  }

  void _openProductSheet({int? editIndex}) {
    productIndexToBeUpdated = editIndex;
    description.text = '';
    quantity.text    = '';
    unitPrice.text   = '';
    if (editIndex != null) {
      final p = productItem[editIndex];
      description.text = p.name ?? '';
      quantity.text    = p.quantity?.toString() ?? '';
      unitPrice.text   = p.price?.toString() ?? '';
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductSheet(
        formKey: _productFormKey,
        description: description, quantity: quantity, unitPrice: unitPrice,
        isEditing: editIndex != null,
        onPickCatalog: _pickFromCatalog,
        onConfirm: () async {
          if (!(_productFormKey.currentState?.validate() ?? false)) return;
          await _confirmProduct(ctx);
        },
      ),
    );
  }

  Future<void> _confirmProduct(BuildContext sheetCtx) async {
    final name  = description.text.trim();
    final qty   = int.tryParse(quantity.text.trim()) ?? 0;
    final price = double.tryParse(unitPrice.text.trim()) ?? 0;

    if (productIndexToBeUpdated == null) {
      final catalog = await db.getCatalogProducts();
      if (!catalog.any((p) => p.name?.toLowerCase() == name.toLowerCase())) {
        await db.insertCatalogProduct(CatalogProduct(name: name, defaultPrice: price));
      }
    }
    setState(() {
      if (productIndexToBeUpdated != null) {
        final p = productItem[productIndexToBeUpdated!];
        p.name = name; p.quantity = qty; p.price = price;
      } else {
        productItem.add(ProductItem(name: name, quantity: qty, price: price));
      }
    });
    Navigator.pop(sheetCtx);
  }

  // ── KEY FIX: showDialog overlays on top of the open bottom sheet ─────────────
  Future<void> _pickFromCatalog() async {
    final catalog = await db.getCatalogProducts();
    if (!mounted) return;
    if (catalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products in catalog yet.')));
      return;
    }
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CatalogPickerDialog(
        catalog: catalog,
        onPick: (p) {
          description.text = p.name ?? '';
          unitPrice.text   = p.defaultPrice?.toStringAsFixed(2) ?? '';
        },
      ),
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (_) => DeleteConfirmationDialog(onDelete: () {
        if (productItem[index].id != null) {
          deletedProductIds.add(productItem[index].id!);
        }
        setState(() => productItem.removeAt(index));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.invoice != null;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: _kBg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 120, pinned: true,
          backgroundColor: _kBg, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _kTextPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEdit ? 'Edit Invoice' : 'New Invoice',
                      style: const TextStyle(color: _kTextPrimary, fontSize: 20,
                          fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  if (invoiceNumber.text.isNotEmpty)
                    Text('# ${invoiceNumber.text}',
                        style: const TextStyle(color: _kGold, fontSize: 11,
                            fontWeight: FontWeight.w500)),
                ]),
            background: Stack(children: [
              Container(decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff1A0A10), _kBg]))),
              Positioned(top: -30, right: -30,
                  child: Opacity(opacity: 0.07,
                      child: Container(width: 200, height: 200,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _kPrimary)))),
            ]),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              decoration: BoxDecoration(color: _kPrimary,
                  borderRadius: BorderRadius.circular(10)),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () => _openProductSheet(),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Form(key: _customerFormKey, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('INVOICE DETAILS'),
            const SizedBox(height: 12),
            _DarkCard(child: Column(children: [
              _buildField(controller: invoiceNumber,
                  label: 'Invoice Number', hint: 'Auto-generated if blank', icon: Icons.tag),
              _divider(),
              _buildTypeahead(),
              _divider(),
              _buildField(controller: customerAddress,
                  label: 'Customer Address', hint: 'Street, City, Country',
                  icon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'Address required' : null),
              _divider(),
              _buildDateField(),
            ])),
            const SizedBox(height: 24),
          ])),
        )),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _sectionLabel('LINE ITEMS'),
            Text('${productItem.length} item${productItem.length == 1 ? '' : 's'}',
                style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        productItem.isEmpty
            ? SliverToBoxAdapter(child: _emptyProducts())
            : SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _ProductCard(item: productItem[i], index: i,
                  onEdit: () => _openProductSheet(editIndex: i),
                  onDelete: () => _deleteProduct(i)),
            ), childCount: productItem.length)),

        if (productItem.isNotEmpty)
          SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _TotalCard(total: _grandTotal))),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),

      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.easeOutBack),
        child: FloatingActionButton.extended(
          backgroundColor: _kPrimary, foregroundColor: Colors.white, elevation: 10,
          onPressed: _saveInvoice,
          icon: const Icon(Icons.check_rounded, size: 20),
          label: Text(isEdit ? 'Update Invoice' : 'Save Invoice',
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14, letterSpacing: 0.3)),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(color: _kTextSecondary, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 1.4));

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: _kBorder, indent: 16, endIndent: 16);

  Widget _buildField({
    required TextEditingController controller,
    required String label, required String hint, required IconData icon,
    String? Function(String?)? validator, bool readOnly = false, Widget? suffix,
  }) => TextFormField(
    controller: controller, readOnly: readOnly, validator: validator,
    cursorColor: _kAccent,
    style: const TextStyle(color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 12),
      hintStyle: const TextStyle(color: Color(0xff4A4860), fontSize: 13),
      prefixIcon: Icon(icon, color: _kTextSecondary, size: 18),
      suffixIcon: suffix, border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      errorStyle: const TextStyle(color: _kAccent, fontSize: 11),
    ),
  );

  Widget _buildTypeahead() => TypeAheadFormField<Customer>(
    suggestionsBoxController: _suggestionsBoxController,
    textFieldConfiguration: TextFieldConfiguration(
      controller: customerName, cursorColor: _kAccent,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: const InputDecoration(
        labelText: 'Customer Name', hintText: 'Search or type new name',
        labelStyle: TextStyle(color: _kTextSecondary, fontSize: 12),
        hintStyle: TextStyle(color: Color(0xff4A4860), fontSize: 13),
        prefixIcon: Icon(Icons.person_outline, color: _kTextSecondary, size: 18),
        suffixIcon: Icon(Icons.expand_more, color: _kTextSecondary, size: 18),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        errorStyle: TextStyle(color: _kAccent, fontSize: 11),
      ),
    ),
    hideOnEmpty: false, hideOnError: true, hideSuggestionsOnKeyboardHide: true,
    suggestionsBoxDecoration: SuggestionsBoxDecoration(
      color: _kSurface2, borderRadius: BorderRadius.circular(14),
      elevation: 12, shadowColor: Colors.black54,
      constraints: const BoxConstraints(maxHeight: 220),
    ),
    validator: (v) => (v == null || v.isEmpty) ? 'Customer name required' : null,
    suggestionsCallback: _searchCustomers,
    itemBuilder: (_, Customer c) => ListTile(
      dense: true,
      leading: CircleAvatar(radius: 16,
        backgroundColor: _kPrimary.withOpacity(0.15),
        child: Text((c.name ?? '?')[0].toUpperCase(),
            style: const TextStyle(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      title: Text(c.name ?? '',
          style: const TextStyle(color: _kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(c.address ?? '',
          style: const TextStyle(color: _kTextSecondary, fontSize: 11)),
    ),
    noItemsFoundBuilder: (_) => const Padding(
      padding: EdgeInsets.all(16),
      child: Text('No match — will be saved as new customer.',
          style: TextStyle(color: _kTextSecondary, fontSize: 12)),
    ),
    onSuggestionSelected: (Customer c) {
      setState(() {
        customerName.text    = c.name ?? '';
        customerAddress.text = c.address ?? '';
      });
      _suggestionsBoxController.close();
    },
  );

  Widget _buildDateField() => TextFormField(
    controller: invoiceDate, readOnly: true, onTap: _datePicker,
    validator: (v) => (v == null || v.isEmpty) ? 'Date required' : null,
    cursorColor: _kAccent,
    style: const TextStyle(color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
    decoration: const InputDecoration(
      labelText: 'Invoice Date', hintText: 'Tap to select',
      labelStyle: TextStyle(color: _kTextSecondary, fontSize: 12),
      hintStyle: TextStyle(color: Color(0xff4A4860), fontSize: 13),
      prefixIcon: Icon(Icons.calendar_today_outlined, color: _kTextSecondary, size: 18),
      suffixIcon: Icon(Icons.chevron_right, color: _kTextSecondary, size: 18),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      errorStyle: TextStyle(color: _kAccent, fontSize: 11),
    ),
  );

  Widget _emptyProducts() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: _DarkCard(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(children: [
        Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.inventory_2_outlined, color: _kPrimary, size: 26)),
        const SizedBox(height: 12),
        const Text('No items yet',
            style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('Tap + in the top right to add a line item',
            style: TextStyle(color: _kTextSecondary, fontSize: 13)),
      ]),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: _kSurface,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
  );
}

class _ProductCard extends StatelessWidget {
  final ProductItem item;
  final int index;
  final VoidCallback onEdit, onDelete;
  const _ProductCard({required this.item, required this.index,
    required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = (item.quantity ?? 0) * (item.price ?? 0);
    return Container(
      decoration: BoxDecoration(color: _kSurface,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('${index + 1}',
                style: const TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('${item.quantity} × ${item.price?.toStringAsFixed(2)}',
              style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
        ])),
        Text(total.toStringAsFixed(2),
            style: const TextStyle(color: _kGold, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _btn(Icons.edit_outlined, _kTextSecondary, onEdit),
          _btn(Icons.delete_outline, Colors.redAccent, onDelete),
        ]),
      ]),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback cb) => GestureDetector(
      onTap: cb,
      child: Padding(padding: const EdgeInsets.all(5),
          child: Icon(icon, color: color, size: 17)));
}

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_kPrimaryDim, _kPrimary],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('GRAND TOTAL', style: TextStyle(color: Colors.white70,
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      Text(total.toStringAsFixed(2), style: const TextStyle(color: Colors.white,
          fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
    ]),
  );
}

class _ProductSheet extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController description, quantity, unitPrice;
  final bool isEditing;
  final VoidCallback onPickCatalog, onConfirm;

  const _ProductSheet({required this.formKey, required this.description,
    required this.quantity, required this.unitPrice, required this.isEditing,
    required this.onPickCatalog, required this.onConfirm});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(12),
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
    decoration: BoxDecoration(color: _kSurface,
        borderRadius: BorderRadius.circular(24), border: Border.all(color: _kBorder)),
    child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isEditing ? 'Edit Item' : 'Add Item',
              style: const TextStyle(color: _kTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          if (!isEditing)
            GestureDetector(
              onTap: onPickCatalog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kPrimary.withOpacity(0.4))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inventory_2_outlined, color: _kAccent, size: 13),
                  SizedBox(width: 5),
                  Text('Catalog', style: TextStyle(color: _kAccent, fontSize: 12,
                      fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
      ),
      const Divider(height: 1, color: _kBorder),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _SheetField(controller: description, label: 'Description',
            hint: 'Product or service name', icon: Icons.label_outline,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: _SheetField(controller: quantity, label: 'Qty', hint: '1',
              icon: Icons.numbers, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _SheetField(controller: unitPrice,
              label: 'Unit Price', hint: '0.00', icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid';
                return null;
              })),
        ]),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0),
            child: Text(isEditing ? 'Save Changes' : 'Add to Invoice',
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 15, letterSpacing: 0.2)),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ])),
  );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SheetField({required this.controller, required this.label,
    required this.hint, required this.icon, this.keyboardType,
    this.inputFormatters, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, keyboardType: keyboardType,
    inputFormatters: inputFormatters, validator: validator,
    cursorColor: _kAccent,
    style: const TextStyle(color: _kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 12),
      hintStyle: const TextStyle(color: Color(0xff3E3C52), fontSize: 13),
      prefixIcon: Icon(icon, color: _kTextSecondary, size: 17),
      filled: true, fillColor: _kSurface2,
      errorStyle: const TextStyle(color: _kAccent, fontSize: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    ),
  );
}

// ── Catalog Picker Dialog ──────────────────────────────────────────────────────
// showDialog (not showModalBottomSheet) so it renders on top of the product sheet

class _CatalogPickerDialog extends StatefulWidget {
  final List<CatalogProduct> catalog;
  final void Function(CatalogProduct) onPick;
  const _CatalogPickerDialog({required this.catalog, required this.onPick});

  @override
  State<_CatalogPickerDialog> createState() => _CatalogPickerDialogState();
}

class _CatalogPickerDialogState extends State<_CatalogPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.catalog
        : widget.catalog
        .where((p) => (p.name ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
        decoration: BoxDecoration(color: _kSurface,
            borderRadius: BorderRadius.circular(20), border: Border.all(color: _kBorder)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Product Catalog',
                  style: TextStyle(color: _kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _kSurface2,
                      borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorder)),
                  child: const Icon(Icons.close, color: _kTextSecondary, size: 16),
                ),
              ),
            ]),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              autofocus: true,
              cursorColor: _kAccent,
              style: const TextStyle(color: _kTextPrimary, fontSize: 13),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search products…',
                hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _kTextSecondary, size: 18),
                filled: true, fillColor: _kSurface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAccent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          // List
          Flexible(
            child: filtered.isEmpty
                ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No products found.',
                    style: TextStyle(color: _kTextSecondary, fontSize: 13)))
                : ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ListTile(
                    onTap: () { widget.onPick(p); Navigator.pop(context); },
                    leading: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: _kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.inventory_2_outlined, color: _kAccent, size: 17)),
                    title: Text(p.name ?? '',
                        style: const TextStyle(color: _kTextPrimary, fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    trailing: Text(p.defaultPrice?.toStringAsFixed(2) ?? '',
                        style: const TextStyle(color: _kGold, fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  );
                }),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _kSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: const Padding(
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 32),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2.5)),
        SizedBox(width: 18),
        Text('Saving…', style: TextStyle(color: _kTextPrimary, fontSize: 15,
            fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}