/// A failure with a message that is safe to show directly to the user.
///
/// Services throw this instead of a raw [Exception] so the UI can display
/// `e.message` without a `Exception: ` prefix leaking into a SnackBar.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}
