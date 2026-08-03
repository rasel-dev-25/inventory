/// The closed set of ways a domain/data operation can fail.
///
/// A `sealed class` so every `switch` over [Failure] is exhaustive — adding
/// a new failure kind forces every handler in the app to consciously decide
/// what to do with it, instead of silently falling through to a generic
/// catch block (the old codebase's `catch (Object e)` pattern that this is
/// designed to replace).
library;

sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The device has no usable connection when one was required for this
/// specific operation (most operations should NOT throw this — offline is
/// the normal case and writes should queue instead).
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection']);
}

/// User-supplied input failed validation before it ever reached storage.
final class ValidationFailure extends Failure {
  final String field;
  const ValidationFailure(this.field, String message) : super(message);
}

/// A requested entity does not exist (wrong id, already deleted, etc).
final class NotFoundFailure extends Failure {
  final String entityType;
  final String id;
  const NotFoundFailure(this.entityType, this.id)
    : super('$entityType "$id" not found');
}

/// The operation is not permitted for the current role (e.g. staff trying
/// to view investor data). This must also be enforced server-side by RLS —
/// this failure is the client-side UX signal, never the security boundary.
final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Not permitted for this role']);
}

/// A sync push was rejected because the local and server state diverged in
/// a way that could not be resolved automatically (e.g. an immutable ledger
/// row was somehow re-sent with different content).
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// A business rule was violated (e.g. attempting to sell more than the
/// available stock, or missing a required fundSource).
final class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure(super.message);
}

/// An unexpected, unclassified error. The [cause] is preserved so it can be
/// logged with full detail even though callers only branch on the
/// [Failure] type.
final class UnknownFailure extends Failure {
  final Object cause;
  final StackTrace? stackTrace;
  const UnknownFailure(this.cause, {this.stackTrace})
    : super('Unexpected error: $cause');
}
