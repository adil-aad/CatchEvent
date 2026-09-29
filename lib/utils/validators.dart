/// Form field validators shared by the auth and event forms.
///
/// Each method returns `null` when the value is valid, or an error message
/// to display under the field.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Generic "must not be empty" check. [fieldName] is used in the message.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? name(String? value) {
    final error = required(value, 'Name');
    if (error != null) return error;
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? email(String? value) {
    final error = required(value, 'Email');
    if (error != null) return error;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final error = required(value, 'Password');
    if (error != null) return error;
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates the "Maximum Participants" field: a positive whole number.
  static String? capacity(String? value) {
    final error = required(value, 'Maximum participants');
    if (error != null) return error;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) {
      return 'Enter a whole number';
    }
    if (parsed < 1) {
      return 'Capacity must be at least 1';
    }
    return null;
  }

  /// Event images are supplied as a URL. The field is optional, but when a
  /// value is given it must be a well-formed http(s) URL.
  static String? imageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optional — the card falls back to a placeholder
    }
    final uri = Uri.tryParse(value.trim());
    final isHttp =
        uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    // `host` must be checked too: "https:/foo" parses but points nowhere.
    if (!isHttp || uri.host.isEmpty) {
      return 'Enter a valid http(s) image URL';
    }
    return null;
  }
}
