import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'rental_dao.g.dart';

@DriftAccessor(tables: [RentBooks, BookRentals])
class RentalDao extends DatabaseAccessor<AppDatabase> with _$RentalDaoMixin {
  RentalDao(super.db);

  // Rent Books
  Future<List<RentBook>> getBooks() => select(rentBooks).get();

  Future<void> addBook(RentBooksCompanion entry) => into(rentBooks).insert(entry);

  Future<void> deleteBook(String id) {
    return (delete(rentBooks)..where((t) => t.id.equals(id))).go();
  }

  // Book Rentals
  Future<List<BookRental>> getRentals() => select(bookRentals).get();

  Future<List<BookRental>> getActiveRentals() {
    return (select(bookRentals)..where((t) => t.dateReturned.equals(''))).get();
  }

  Future<void> addRental(BookRentalsCompanion entry) => into(bookRentals).insert(entry);

  Future<void> updateRental(String id, BookRentalsCompanion entry) {
    return (update(bookRentals)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteRental(String id) {
    return (delete(bookRentals)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markReturned(String id, String dateReturned) {
    return (update(bookRentals)..where((t) => t.id.equals(id)))
        .write(BookRentalsCompanion(dateReturned: Value(dateReturned)));
  }

  Future<void> markPaid(String id) {
    return (update(bookRentals)..where((t) => t.id.equals(id)))
        .write(const BookRentalsCompanion(isPaid: Value(true)));
  }
}
