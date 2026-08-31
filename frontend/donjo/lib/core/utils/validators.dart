class Validators {
  static final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateRequired(
    String? value, [
    String field = 'This field',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// The code emailed by the password-reset flow. Six digits.
  static String? validateResetCode(String? value) {
    final String code = value?.trim() ?? '';
    if (code.isEmpty) {
      return 'Enter the code we emailed you';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'The code is 6 digits';
    }
    return null;
  }
}
