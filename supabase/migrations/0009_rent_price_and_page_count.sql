-- Two columns the M3 Rent module needs that were missing from the
-- original schema:
--
-- 1. products.page_count — notes/business_logic.md §জ: "ভাড়া দেওয়ার সময়
--    বইয়ের pageCount অনুযায়ী RentPricingTier থেকে days ও price
--    অটো-সাজেস্ট হবে" (the tier lookup at rent-issue time is keyed by the
--    book's page count). Nullable: only meaningful for rentable books,
--    same as is_rentable itself being a general flag rather than a
--    category-restricted column.
--
-- 2. rent_transactions.rent_price_minor — the agreed basic rental price
--    at issue time (tier-suggested or manually overridden per the
--    spec's "ম্যানুয়াল ওভাররাইড করা যাবে"). This was missing from the
--    original rent_transactions table entirely — there was no column to
--    record what the tier lookup actually produced, only the
--    deposit/extra-day/damage charges. Required (not nullable): every
--    rental has an agreed price the moment it's issued, unlike
--    extra_day_charge_minor/damage_charge_minor which are only known at
--    return time.
alter table products
  add column page_count int check (page_count > 0);

alter table rent_transactions
  add column rent_price_minor bigint not null default 0 check (rent_price_minor >= 0);

-- The default above only exists to satisfy the not-null constraint on an
-- (empty, pre-launch) table; every real insert going forward always
-- supplies a real value via RentDao.create, matching how every other
-- required-at-write-time column in this schema works.
