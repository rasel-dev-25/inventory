import 'enums.dart';

/// A customer pre-order, per `notes/business_logic.md` §Order.
///
/// "Customer পেজের 'অর্ডার দাতা' ট্যাব এই Order টেবিল থেকে ফিল্টার করা ভিউ" —
/// an order-giver is a view over [Order] joined with `Customer`, same as
/// every other customer role the spec describes (buyer/renter/due-taker);
/// see `Customer`'s own doc comment. This entity carries no reference to
/// a [Product] on purpose — [itemDescription] is free text, matching the
/// spec's "কী চান" (what they want), which is often not yet in stock at
/// all (that's the point of a pre-order).
class Order {
  final String id;
  final String customerId;
  final String itemDescription;
  final DateTime requestedDate;
  final DateTime? neededByDate;
  final OrderStatus status;
  final DateTime? fulfilledDate;

  const Order({
    required this.id,
    required this.customerId,
    required this.itemDescription,
    required this.requestedDate,
    required this.status,
    this.neededByDate,
    this.fulfilledDate,
  });

  Order copyWith({OrderStatus? status, DateTime? fulfilledDate}) {
    return Order(
      id: id,
      customerId: customerId,
      itemDescription: itemDescription,
      requestedDate: requestedDate,
      neededByDate: neededByDate,
      status: status ?? this.status,
      fulfilledDate: fulfilledDate ?? this.fulfilledDate,
    );
  }
}
