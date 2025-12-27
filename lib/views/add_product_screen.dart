import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../viewmodels/stock_viewmodel.dart';
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
  late TextEditingController _categoryController;
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
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
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
    _categoryController.dispose();
    _qtyController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(image.path);
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _selectedImages.add(savedImage.path);
      });
    }
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
        category: _categoryController.text.isEmpty ? 'General' : _categoryController.text,
        quantity: int.parse(_qtyController.text),
        costPrice: double.parse(_costPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        supplier: _supplierController.text,
        images: _selectedImages,
      );

      final viewModel = Provider.of<StockViewModel>(context, listen: false);
      if (widget.product != null) {
        viewModel.updateProduct(product);
      } else {
        viewModel.addProduct(product);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Product" : "Add Product"),
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
                        onTap: _pickImage,
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
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index])),
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

              _buildTextField(_nameController, "Product Name", icon: Icons.shopping_bag_outlined),
              const SizedBox(height: 15),
              _buildTextField(_skuController, "SKU / Barcode", icon: Icons.qr_code),
              const SizedBox(height: 15),
              _buildTextField(_categoryController, "Category", icon: Icons.category_outlined),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildTextField(_qtyController, "Quantity", isNumber: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField(_sellingPriceController, "Selling Price", isNumber: true, prefix: "\$")),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildTextField(_costPriceController, "Cost Price", isNumber: true, prefix: "\$")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTextField(_supplierController, "Supplier", icon: Icons.local_shipping_outlined)),
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
                  isEditing ? "Update Product" : "Save Product",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: AppColors.grisMaster)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, IconData? icon, String? prefix}) {
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
          return 'Required';
        }
        if (isNumber && double.tryParse(value) == null) {
          return 'Invalid Number';
        }
        return null;
      },
    );
  }
}
