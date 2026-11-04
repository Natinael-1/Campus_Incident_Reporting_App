import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';

class CreateIncidentScreen extends StatefulWidget {
  final VoidCallback? onReportSubmitted;

  const CreateIncidentScreen({
    super.key,
    this.onReportSubmitted,
  });

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = AppConstants.categories.first; // 'Facilities'
  String _selectedLocation = AppConstants.campusLocations[1]; // 'Block B — Room 204'
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Opens a bottom sheet letting the student pick a photo from Camera or Gallery
  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConstants.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Attach Incident Photo',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 12.0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppConstants.lightBlueSurface,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                  title: const Text(
                    'Take a Photo with Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppConstants.lightBlueSurface,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select image: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    final IncidentProvider incidentProvider = context.read<IncidentProvider>();
    final UserModel? currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to submit an incident report.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bool success = await incidentProvider.submitIncident(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      location: _selectedLocation,
      reportedByUid: currentUser.uid,
      reportedByName: currentUser.name,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      // Clear form fields after successful submission
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
        _selectedCategory = AppConstants.categories.first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident report submitted successfully!'),
          backgroundColor: AppConstants.resolvedText,
        ),
      );

      if (widget.onReportSubmitted != null) {
        widget.onReportSubmitted!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      final String error = incidentProvider.errorMessage ??
          'Failed to submit report. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSubmitting = context.watch<IncidentProvider>().isSubmitting;

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppConstants.textDark),
        title: const Text(
          'Report an Incident',
          style: TextStyle(
            color: AppConstants.textDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. Category Selector Grid (5 Categories from Canvas UI)
                const Text(
                  'Select a category',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildCategoryGrid(),
                const SizedBox(height: 22.0),

                // 2. Title Field
                CustomTextField(
                  label: 'Title',
                  hintText: 'Briefly describe the issue...',
                  controller: _titleController,
                  validator: Validators.validateTitle,
                ),
                const SizedBox(height: 18.0),

                // 3. Description Field
                CustomTextField(
                  label: 'Description',
                  hintText:
                      'Provide more details about the issue...\ne.g. what happened, when, impact, etc.',
                  controller: _descriptionController,
                  validator: Validators.validateDescription,
                  maxLines: 4,
                ),
                const SizedBox(height: 18.0),

                // 4. Location Dropdown
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppConstants.textSecondary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: AppConstants.textSecondary,
                      size: 20.0,
                    ),
                    filled: true,
                    fillColor: AppConstants.cardWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 14.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppConstants.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppConstants.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppConstants.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: AppConstants.campusLocations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: AppConstants.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLocation = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 18.0),

                // 5. Optional Photo Attachment Box
                const Row(
                  children: <Widget>[
                    Text(
                      'Add a photo ',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                    Text(
                      '(optional)',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                _buildPhotoPickerBox(),
                const SizedBox(height: 28.0),

                // 6. Submit Report Button
                SizedBox(
                  width: double.infinity,
                  height: 52.0,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryBlue,
                      foregroundColor: AppConstants.cardWhite,
                      disabledBackgroundColor:
                          AppConstants.primaryBlue.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22.0,
                            height: 22.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppConstants.cardWhite,
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the 5 category icon buttons (3 on top row, 2 on bottom row) matching the sample UI
  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: AppConstants.categories.map((String category) {
        final bool isSelected = _selectedCategory == category;
        // Calculate width so 3 tiles fit per row cleanly
        final double tileWidth =
            (MediaQuery.of(context).size.width - 40.0 - 20.0) / 3;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: tileWidth,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryBlue
                  : AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryBlue
                    : AppConstants.borderColor,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  AppConstants.getCategoryIcon(category),
                  color: isSelected
                      ? AppConstants.cardWhite
                      : AppConstants.primaryBlue,
                  size: 24.0,
                ),
                const SizedBox(height: 6.0),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppConstants.cardWhite
                        : AppConstants.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the "Tap to add photos" box or displays the selected image preview with a remove button
  Widget _buildPhotoPickerBox() {
    if (_selectedImage != null) {
      return Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14.0),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 180.0,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8.0,
            right: 8.0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: 110.0,
        decoration: BoxDecoration(
          color: AppConstants.cardWhite,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.add_photo_alternate_outlined,
              color: AppConstants.primaryBlue,
              size: 30.0,
            ),
            SizedBox(height: 6.0),
            Text(
              'Tap to add photos',
              style: TextStyle(
                fontSize: 13.0,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}