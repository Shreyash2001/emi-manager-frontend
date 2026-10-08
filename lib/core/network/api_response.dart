/// Generic API response wrapper matching the backend contract:
///
/// Success:
/// ```json
/// { "success": true, "message": "...", "data": {} }
/// ```
///
/// Error:
/// ```json
/// { "success": false, "message": "...", "error": { "code": "...", "details": [] } }
/// ```
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, data: $data)';
}
