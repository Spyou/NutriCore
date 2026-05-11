class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? barcode(String? value) {
    if (value == null || value.isEmpty) return 'Barcode is required';
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 8 || digits.length > 14) {
      return 'Invalid barcode format';
    }
    return null;
  }

  static String? weight(double? value) {
    if (value == null) return 'Weight is required';
    if (value <= 0 || value > 1000) {
      return 'Weight must be between 0 and 1000 kg';
    }
    return null;
  }

  static String? height(double? value) {
    if (value == null) return 'Height is required';
    if (value <= 0 || value > 300) return 'Height must be between 0 and 300 cm';
    return null;
  }

  static String? age(int? value) {
    if (value == null) return 'Age is required';
    if (value <= 0 || value > 150) return 'Age must be between 1 and 150';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? searchQuery(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 2) {
      return 'Search query must be at least 2 characters';
    }
    return null;
  }
}
