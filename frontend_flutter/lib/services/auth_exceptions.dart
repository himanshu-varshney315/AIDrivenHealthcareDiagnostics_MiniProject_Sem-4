class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException([super.message = 'Authentication required.']);
}

class ForbiddenException extends AuthException {
  const ForbiddenException([
    super.message = 'You do not have permission to access this resource.',
  ]);
}
