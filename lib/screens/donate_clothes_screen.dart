import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DonateClothesScreen extends StatefulWidget {
  const DonateClothesScreen({super.key});

  @override
  State<DonateClothesScreen> createState() => _DonateClothesScreenState();
}

class _DonateClothesScreenState extends State<DonateClothesScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  DateTime? _pickupDate;

  final _formKey = GlobalKey<FormState>();

  String category = "Shirt";
  String size = "M";
  String condition = "Good";

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _pickupDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate Clothes")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 📸 Image Picker
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage:
                        _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null
                        ? const Icon(Icons.camera_alt,
                            size: 40, color: Colors.green)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 👕 Category
              DropdownButtonFormField(
                value: category,
                items: const [
                  DropdownMenuItem(value: "Shirt", child: Text("Shirt")),
                  DropdownMenuItem(value: "Pants", child: Text("Pants")),
                  DropdownMenuItem(value: "Saree", child: Text("Saree")),
                  DropdownMenuItem(value: "Jacket", child: Text("Jacket")),
                ],
                onChanged: (value) => setState(() => category = value.toString()),
                decoration: const InputDecoration(
                  labelText: "Cloth Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // 📏 Size
              DropdownButtonFormField(
                value: size,
                items: const [
                  DropdownMenuItem(value: "S", child: Text("Small")),
                  DropdownMenuItem(value: "M", child: Text("Medium")),
                  DropdownMenuItem(value: "L", child: Text("Large")),
                ],
                onChanged: (value) => setState(() => size = value.toString()),
                decoration: const InputDecoration(
                  labelText: "Size",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // 🧺 Condition
              DropdownButtonFormField(
                value: condition,
                items: const [
                  DropdownMenuItem(value: "New", child: Text("New")),
                  DropdownMenuItem(value: "Good", child: Text("Good")),
                  DropdownMenuItem(value: "Used", child: Text("Used")),
                ],
                onChanged: (value) =>
                    setState(() => condition = value.toString()),
                decoration: const InputDecoration(
                  labelText: "Condition",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // 📍 Address
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Pickup Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // 📅 Pickup Date
              ElevatedButton.icon(
                onPressed: () => selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _pickupDate == null
                      ? "Select Pickup Date"
                      : "Pickup Date: ${_pickupDate!.year}-${_pickupDate!.month.toString().padLeft(2, '0')}-${_pickupDate!.day.toString().padLeft(2, '0')}",
                ),
              ),

              const SizedBox(height: 25),

              // 🚀 Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Donation Submitted!")),
                      );
                    }
                  },
                  child: const Text("Submit Donation",
                      style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
