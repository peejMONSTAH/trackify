import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _profileImagePath;
  final _authService = AuthService();
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    // Load user profile
    final profile = await UserProfileService.getUserProfile();
    _userName = profile['name'];
    _userPhone = profile['phone'];

    // Get user email from Firebase Auth
    final user = _authService.currentUser;
    _userEmail = user?.email ?? 'No email';

    // Load profile image (per-user)
    _profileImagePath = await UserProfileService.getProfileImagePath(user?.uid);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // Get app documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = path.basename(image.path);
        final savedImage = File(path.join(directory.path, fileName));
        
        // Copy image to app directory
        await File(image.path).copy(savedImage.path);
        
        // Save path to SharedPreferences (per-user)
        final user = _authService.currentUser;
        await UserProfileService.saveProfileImagePath(
          savedImage.path,
          user?.uid,
        );

        if (mounted) {
          setState(() {
            _profileImagePath = savedImage.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final user = _authService.currentUser;
                  await UserProfileService.clearProfileImage(user?.uid);
                  setState(() {
                    _profileImagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Picture - Clickable to change
                  GestureDetector(
                    onTap: _showImagePicker,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Constants.primaryBlue,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Constants.primaryBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Constants.primaryBlue,
                            backgroundImage: _profileImagePath != null &&
                                    File(_profileImagePath!).existsSync()
                                ? FileImage(File(_profileImagePath!))
                                : null,
                            child: _profileImagePath == null ||
                                    !File(_profileImagePath!).existsSync()
                                ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Constants.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showImagePicker,
                    child: const Text(
                      'Change Photo',
                      style: TextStyle(color: Constants.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Name (Read-only)
                  _buildInfoCard(
                    'Name',
                    _userName ?? 'Not set',
                    Icons.person,
                    Constants.primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  // Email (Read-only)
                  _buildInfoCard(
                    'Email',
                    _userEmail ?? 'Not set',
                    Icons.email,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  // Phone (Read-only)
                  _buildInfoCard(
                    'Phone',
                    _userPhone ?? 'Not set',
                    Icons.phone,
                    Colors.green,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
