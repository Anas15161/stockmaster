import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  // Category handled by dropdown
  String? _selectedCategory;
  
  late TextEditingController _qtyController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _supplierController;

  List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    
    // Set initial category
    if (widget.product?.category != null && widget.product!.category.isNotEmpty) {
      _selectedCategory = widget.product!.category;
    }

    _qtyController = TextEditingController(text: widget.product?.quantity.toString() ?? '');
    _costPriceController = TextEditingController(text: widget.product?.costPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _supplierController = TextEditingController(text: widget.product?.supplier ?? '');
    
    if (widget.product != null) {
      _selectedImages = List.from(widget.product!.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _qtyController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(image.path);
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _selectedImages.add(savedImage.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    final languageViewModel = Provider.of<LanguageViewModel>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(languageViewModel.translate('gallery')),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(languageViewModel.translate('camera')),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id, // Keep ID for updates
        name: _nameController.text,
        sku: _skuController.text,
        category: _selectedCategory ?? 'General',
        quantity: int.parse(_qtyController.text),
        costPrice: double.parse(_costPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        supplier: _supplierController.text,
        images: _selectedImages,
      );

      final viewModel = Provider.of<StockViewModel>(context, listen: false);
      if (widget.product?.id != null) {
        viewModel.updateProduct(product);
      } else {
        viewModel.addProduct(product);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product?.id != null;
    final languageViewModel = Provider.of<LanguageViewModel>(context);
    final stockViewModel = Provider.of<StockViewModel>(context);

    // Ensure selected category is valid (in case list changed), or keep it if editing existing
    // If _selectedCategory is not in stockViewModel.categories, we might want to add it or show it anyway.
    // For now, we will assume it's valid or allow it if it was already set.
    // But to populate the dropdown, we need unique items.
    
    // Combine existing categories with selected if missing (for legacy support)
    Set<String> dropdownItems = Set.from(stockViewModel.categories);
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      dropdownItems.add(_selectedCategory!);
    }
    if (dropdownItems.isEmpty) dropdownItems.add('General');
    
    final categoryValue = dropdownItems.contains(_selectedCategory) ? _selectedCategory : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? languageViewModel.translate('edit_product') : languageViewModel.translate('add_product')),
        backgroundColor: AppColors.bleuStock,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                  itemBuilder: (ctx, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: () => _showImageSourceActionSheet(context),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        ),
                      );
                    }
                    final imagePath = _selectedImages[index];
                    final isNetworkImage = imagePath.startsWith('http');

                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: isNetworkImage
                                  ? NetworkImage(imagePath) as ImageProvider
                                  : FileImage(File(imagePath)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              color: Colors.black54,
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(_nameController, languageViewModel.translate('product_name'), languageViewModel, icon: Icons.shopping_bag_outlined),
              const SizedBox(height: 15),
              _buildTextField(_skuController, languageViewModel.translate('sku_barcode'), languageViewModel, icon: Icons.qr_code),
              const SizedBox(height: 15),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                key: ValueKey(categoryValue),
                initialValue: categoryValue,
                decoration: InputDecoration(
                  labelText: languageViewModel.translate('category'),
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.grisMaster),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.bleuStock, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: dropdownItems.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return languageViewModel.translate('required');
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildTextField(_qtyController, languageViewModel.translate('quantity'), languageViewModel, isNumber: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField(_sellingPriceController, languageViewModel.translate('selling_price'), languageViewModel, isNumber: true, prefix: "\$")),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildTextField(_costPriceController, languageViewModel.translate('cost_price'), languageViewModel, isNumber: true, prefix: "\$")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField(_supplierController, languageViewModel.translate('supplier'), languageViewModel, icon: Icons.local_shipping_outlined)),
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vertCroissance,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isEditing ? languageViewModel.translate('update_product') : languageViewModel.translate('save_product'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(languageViewModel.translate('cancel'), style: const TextStyle(color: AppColors.grisMaster)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, LanguageViewModel languageViewModel, {bool isNumber = false, IconData? icon, String? prefix}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.grisMaster) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.bleuStock, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return languageViewModel.translate('required');
        }
        if (isNumber && double.tryParse(value) == null) {
          return languageViewModel.translate('invalid_number');
        }
        return null;
      },
    );
  }
}