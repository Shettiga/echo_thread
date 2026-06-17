import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/services/cloudinary_service.dart';

class DonateClothesScreen extends StatefulWidget {
  const DonateClothesScreen({super.key});

  @override
  State<DonateClothesScreen> createState() => _DonateClothesScreenState();
}

class _DonateClothesScreenState extends State<DonateClothesScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  DateTime? _pickupDate;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String category = "Shirt";
  String size = "M";
  String condition = "Good";
  String donorName = "Donor";

  bool _isSubmitting = false;
  late final AnimationController _animationController;
  late final List<Animation<double>> _fieldFadeAnimations;

  @override
  void initState() {
    super.initState();
    _fetchDonorName();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Create staggered fade-in animations for the form inputs
    _fieldFadeAnimations = List.generate(
      7,
      (index) => CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (index * 0.1),
          0.4 + (index * 0.1),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _quantityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            donorName = doc.data()?['name'] ?? "Donor";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1B5E20),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _pickupDate = picked;
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a pickup date 📅"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String imageUrl = "";
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('donations').add({
        'donorId': user.uid,
        'donorName': donorName,
        'clothes': category,
        'quantity': _quantityController.text.trim(),
        'size': size,
        'condition': condition,
        'location': _addressController.text.trim(),
        'imageUrl': imageUrl,
        'pickupDate':
            "${_pickupDate!.year}-${_pickupDate!.month.toString().padLeft(2, '0')}-${_pickupDate!.day.toString().padLeft(2, '0')}",
        'status': "Pending",
        'volunteerId': null,
        'volunteerName': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation Submitted Successfully 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error during donation submission or image upload: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          "Donate Clothes",
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 Image Picker
              FadeTransition(
                opacity: _fieldFadeAnimations[0],
                child: Center(
                  child: GestureDetector(
                    onTap: _showImageSourceBottomSheet,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade200, width: 2),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: _selectedImage == null
                          ? Icon(Icons.add_a_photo_outlined,
                              size: 38, color: themeColor)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 👕 Category Selector
              FadeTransition(
                opacity: _fieldFadeAnimations[1],
                child: DropdownButtonFormField(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: "Shirt", child: Text("Shirt 👕")),
                    DropdownMenuItem(value: "Pants", child: Text("Pants 👖")),
                    DropdownMenuItem(value: "Saree", child: Text("Saree 👘")),
                    DropdownMenuItem(value: "Jacket", child: Text("Jacket 🧥")),
                    DropdownMenuItem(value: "Other", child: Text("Other 👗")),
                  ],
                  onChanged: (value) =>
                      setState(() => category = value.toString()),
                  decoration: _inputDecoration("Category", Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // 📏 Size Selector
              FadeTransition(
                opacity: _fieldFadeAnimations[2],
                child: DropdownButtonFormField(
                  value: size,
                  items: const [
                    DropdownMenuItem(value: "S", child: Text("Small (S)")),
                    DropdownMenuItem(value: "M", child: Text("Medium (M)")),
                    DropdownMenuItem(value: "L", child: Text("Large (L)")),
                    DropdownMenuItem(value: "XL", child: Text("Extra Large (XL)")),
                  ],
                  onChanged: (value) => setState(() => size = value.toString()),
                  decoration: _inputDecoration("Size", Icons.photo_size_select_small),
                ),
              ),
              const SizedBox(height: 16),

              // 🧺 Condition
              FadeTransition(
                opacity: _fieldFadeAnimations[3],
                child: DropdownButtonFormField(
                  value: condition,
                  items: const [
                    DropdownMenuItem(value: "New", child: Text("Brand New ✨")),
                    DropdownMenuItem(value: "Good", child: Text("Good Condition 👍")),
                    DropdownMenuItem(value: "Used", child: Text("Gently Used ♻️")),
                  ],
                  onChanged: (value) =>
                      setState(() => condition = value.toString()),
                  decoration: _inputDecoration("Condition", Icons.star_border),
                ),
              ),
              const SizedBox(height: 16),

              // 🔢 Quantity Input
              FadeTransition(
                opacity: _fieldFadeAnimations[4],
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter quantity" : null,
                  decoration: _inputDecoration("Quantity", Icons.format_list_numbered),
                ),
              ),
              const SizedBox(height: 16),

              // 📍 Pickup Address
              FadeTransition(
                opacity: _fieldFadeAnimations[5],
                child: TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter pickup address" : null,
                  decoration: _inputDecoration("Pickup Address", Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 18),

              // 📅 Pickup Date Picker
              FadeTransition(
                opacity: _fieldFadeAnimations[6],
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => selectDate(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: themeColor),
                          const SizedBox(width: 12),
                          Text(
                            _pickupDate == null
                                ? "Select Pickup Date"
                                : "Pickup Date: ${_pickupDate!.year}-${_pickupDate!.month.toString().padLeft(2, '0')}-${_pickupDate!.day.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 16,
                              color: _pickupDate == null ? Colors.black54 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🚀 Animated Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitDonation,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volunteer_activism_outlined, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "Submit Donation",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, IconData prefixIcon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
