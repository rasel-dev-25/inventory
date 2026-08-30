alter table purchase_trips
  add column if not exists actual_cash_taken_out_minor bigint
  check (
    actual_cash_taken_out_minor is null
    or actual_cash_taken_out_minor >= 0
  );
