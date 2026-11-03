class Validators {
  // Prevent this helper class from being instantiated
  Validators._();

  //Validates an email address on the Login and Register screens
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    // Regular expression to check for a valid email pattern 
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null; 
  }

  //Validates a password (Firebase Auth requires at least 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  //
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    return null;
  }

  //
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a short title for the issue';
    }

    if (value.trim().length < 5) {
      return 'Title should be at least 5 characters long';
    }

    return null;
  }

  //
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe the issue in detail';
    }

    if (value.trim().length < 10) {
      return 'Please provide at least 10 characters of detail';
    }

    return null;
  }

  /// Generic validator for dropdowns or any other required field (e.g., Location)
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select or enter a $fieldName';
    }

    return null;
  }
}