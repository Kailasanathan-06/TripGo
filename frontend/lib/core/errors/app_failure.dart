class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? error;

  const ApiException(this.message, {this.statusCode, this.error});

  bool get isNetworkError => statusCode == null && error is Exception && error.toString().contains('SocketException');

  @override
  String toString() => message;
}