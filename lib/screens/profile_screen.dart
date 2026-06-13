import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Loading...";
  String email = "Loading...";
  String phone = "";
  String role = "Loading...";
  String? profileImageUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  File? _selectedProfileImage;

  int totalItems = 0;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;

      // 1. User details
      var userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userData.exists) return;

      final uData = userData.data();
      final userRole = uData?['role'] ?? 'Donor';

      if (mounted) {
        setState(() {
          name = uData?['name'] ?? "User";
          email = uData?['email'] ?? "";
          phone = uData?['phone'] ?? "";
          role = userRole;
          profileImageUrl = uData?['profileImage'];
          nameController.text = name;
          emailController.text = email;
          phoneController.text = phone;
        });
      }

      // 2. Dynamic statistics based on role
      QuerySnapshot donationsSnapshot;
      if (userRole == 'Donor') {
        donationsSnapshot = await FirebaseFirestore.instance
            .collection('donations')
            .where('donorId', isEqualTo: uid)
            .get();

        int garments = 0;
        int completed = 0;
        for (var doc in donationsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final int qty = int.tryParse(data['quantity']?.toString() ?? '1') ?? 1;
          garments += qty;
          if (data['status'] == 'Delivered' || data['status'] == 'Distributed') {
            completed++;
          }
        }

        if (mounted) {
          setState(() {
            totalItems = garments;
            completedCount = completed;
          });
        }
      } else if (userRole == 'Volunteer') {
        donationsSnapshot = await FirebaseFirestore.instance
            .collection('donations')
            .where('volunteerId', isEqualTo: uid)
            .get();

        int deliveries = 0;
        for (var doc in donationsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Delivered' || data['status'] == 'Distributed') {
            deliveries++;
          }
        }

        if (mounted) {
          setState(() {
            totalItems = donationsSnapshot.docs.length;
            completedCount = deliveries;
          });
        }
      } else if (userRole == 'NGO') {
        donationsSnapshot = await FirebaseFirestore.instance.collection('donations').get();

        int active = 0;
        int distributed = 0;
        for (var doc in donationsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Distributed') {
            distributed++;
          } else {
            active++;
          }
        }

        if (mounted) {
          setState(() {
            totalItems = active;
            completedCount = distributed;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile statistics: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedProfileImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
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
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfileChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String newImageUrl = profileImageUrl ?? '';

      // If a new image was picked, upload it to Firebase Storage
      if (_selectedProfileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${user.uid}.jpg');
        await storageRef.putFile(_selectedProfileImage!);
        newImageUrl = await storageRef.getDownloadURL();
      }

      final String newEmail = emailController.text.trim();
      final String newName = nameController.text.trim();
      final String newPhone = phoneController.text.trim();

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': newName,
        'email': newEmail,
        'phone': newPhone,
        'profileImage': newImageUrl,
      });

      // Try updating in Auth
      if (newEmail != user.email) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent to verify new address.'),
              backgroundColor: Colors.orange,
            ),
          );
        } catch (authError) {
          debugPrint("Auth email update error: $authError");
        }
      }

      if (mounted) {
        setState(() {
          name = newName;
          email = newEmail;
          phone = newPhone;
          profileImageUrl = newImageUrl;
          _selectedProfileImage = null;
          _isEditing = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getRoleColor(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          "My Profile",
          style: TextStyle(color: themeColor, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // 👤 AVATAR / PROFILE HERO
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: themeColor, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: themeColor.withOpacity(0.1),
                            backgroundImage: _selectedProfileImage != null
                                ? FileImage(_selectedProfileImage!)
                                : (profileImageUrl != null && profileImageUrl!.isNotEmpty
                                    ? NetworkImage(profileImageUrl!) as ImageProvider
                                    : null),
                            child: _selectedProfileImage == null &&
                                    (profileImageUrl == null || profileImageUrl!.isEmpty)
                                ? Icon(
                                    _getRoleIcon(role),
                                    size: 50,
                                    color: themeColor,
                                  )
                                : null,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _showImageSourceActionSheet(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 4),
                                  ],
                                ),
                                child: Icon(Icons.camera_alt, size: 14, color: themeColor),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (_isEditing) ...[
                    // 📦 EDIT PROFILE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Edit Account Details",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          const Divider(height: 24),
                          TextFormField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Name",
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: Icon(Icons.person_outline, color: themeColor),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: phoneController,
                            style: const TextStyle(color: Colors.black87),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Phone Number",
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: Icon(Icons.phone_outlined, color: themeColor),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.black87),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: Icon(Icons.email_outlined, color: themeColor),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = false;
                                      _selectedProfileImage = null;
                                      nameController.text = name;
                                      emailController.text = email;
                                      phoneController.text = phone;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: themeColor),
                            ),
                            child: Text("Cancel", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfileChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // 📦 USER ACCOUNT CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Account Details",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow("Email", email, Icons.email_outlined, themeColor),
                          const SizedBox(height: 14),
                          _buildDetailRow("Phone", phone.isNotEmpty ? phone : "Not Added", Icons.phone_outlined, themeColor),
                          const SizedBox(height: 14),
                          _buildDetailRow("Access Level", role, Icons.shield_outlined, themeColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 📊 STATISTICS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Performance Stats",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(_getStatTitle1(role), totalItems.toString(), themeColor),
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                            _buildStatColumn(_getStatTitle2(role), completedCount.toString(), themeColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
          ],
        )
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getRoleColor(String r) {
    switch (r) {
      case 'NGO':
        return const Color(0xFFE65100);
      case 'Volunteer':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _getRoleIcon(String r) {
    switch (r) {
      case 'NGO':
        return Icons.home_work_outlined;
      case 'Volunteer':
        return Icons.directions_run_outlined;
      default:
        return Icons.volunteer_activism_outlined;
    }
  }

  String _getStatTitle1(String r) {
    switch (r) {
      case 'NGO':
        return "Active Requests";
      case 'Volunteer':
        return "Assigned Tasks";
      default:
        return "Garments Donated";
    }
  }

  String _getStatTitle2(String r) {
    switch (r) {
      case 'NGO':
        return "Garments Distributed";
      case 'Volunteer':
        return "Garments Delivered";
      default:
        return "Completed Goals";
    }
  }
}