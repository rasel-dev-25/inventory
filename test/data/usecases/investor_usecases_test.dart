import 'package:drift/native.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/investor_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late InvestorUseCases useCases;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCases = InvestorUseCases(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create writes the investor locally and enqueues a matching outbox event',
    () async {
      await useCases.create(
        const Investor(
          id: 'investor-1',
          name: 'Uncle Karim',
          investmentType: InvestmentType.cashMudaraba,
          profitSharePercent: 30,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final stored = await db.investorDao.getById('investor-1');
      expect(stored!.name, 'Uncle Karim');
      expect(stored.profitSharePercent, 30);

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'investor_created',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'investors');
      expect(upserts.single.row['investment_type'], 'cashMudaraba');
    },
  );

  test(
    'update round-trips contact/investmentType/profitSharePercent',
    () async {
      await useCases.create(
        const Investor(
          id: 'investor-1',
          name: 'Uncle Karim',
          investmentType: InvestmentType.cashLoan,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      const updated = Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        contact: '01700000000',
        investmentType: InvestmentType.cashMusharaka,
        profitSharePercent: 25,
        capitalReturnTermDays: 90,
      );
      await useCases.update(
        updated,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      final stored = await db.investorDao.getById('investor-1');
      expect(stored!.contact, '01700000000');
      expect(stored.investmentType, InvestmentType.cashMusharaka);
      expect(stored.profitSharePercent, 25);
      expect(stored.capitalReturnTermDays, 90);
    },
  );
}
