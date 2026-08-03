/// A customer, per `notes/business_logic.md` §Customer.
///
/// "ক্রেতা / অর্ডার দাতা / ভাড়াটে / বাকি" (buyer / order-giver / renter /
/// due-taker) are explicitly *not* separate tables in the spec — they are
/// filtered views over one [Customer] joined with Sale/Order/Rent/Due
/// records. This entity intentionally has no `type` field for that reason;
/// a customer classification lives in a query, not in a stored column, so
/// a single person can be a buyer, a renter, and a due-taker
/// simultaneously without three disconnected records.
class Customer {
  final String id;
  final String name;
  final String? address;
  final String? contact;

  /// Set when the owner marks this customer as a follow-up risk (per
  /// business_logic.md §জ) — e.g. a renter who has been slow to return
  /// books before. Drives repeated reminders, and can gate requiring a
  /// deposit/address on the rent-issue form.
  final bool suspicionFlag;

  /// Set once a rental is escalated to `treated_as_stolen` (see
  /// `RentStatus`) — an [isBlocked] customer should be flagged prominently
  /// wherever they appear (sale, due, rent-issue flows).
  final bool isBlocked;

  const Customer({
    required this.id,
    required this.name,
    this.address,
    this.contact,
    this.suspicionFlag = false,
    this.isBlocked = false,
  });

  Customer copyWith({
    String? name,
    String? address,
    String? contact,
    bool? suspicionFlag,
    bool? isBlocked,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      suspicionFlag: suspicionFlag ?? this.suspicionFlag,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
