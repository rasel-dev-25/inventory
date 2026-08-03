# AL ASHAB — ডেটা কানেকশন ও বিজনেস লজিক (v2 — সঠিক ব্যবসায়িক মডেল অনুযায়ী)

> এটা v1-কে সম্পূর্ণ রিপ্লেস করে — আসল ব্যবসার লজিক অনুযায়ী নতুন করে লেখা।

## ব্যবসার প্রকৃতি (সংক্ষেপে)

- একাধিক **ইনভেস্টর** থেকে **নগদ টাকা** বা **সরাসরি পণ্য (in-kind)** নিয়ে ব্যবসা চলে (মুদারাবা/মুশারাকা ধাঁচে)
- প্রতিটা ইনভেস্টরের সাথে আলাদা চুক্তি: মূলধন ফেরতের সময়সীমা, লাভ ভাগাভাগির পদ্ধতি ও চক্র
- বাজার/মোকাম ট্রিপে একদিনে একাধিক দোকান থেকে জিনিস কেনা হয়, মিশ্র উৎসের টাকায় (দোকানের নিজের ক্যাশ + এক বা একাধিক ইনভেস্টরের টাকা)
- বই ভাড়ার আলাদা প্রাইসিং-টিয়ার সিস্টেম আছে

---

## ১. মূল এনটিটি

### Investor (বিনিয়োগকারী)
```
id, name, contact
investmentType: cash_loan | cash_mudaraba | cash_musharaka | goods_in_kind
profitSharePercent      // মুদারাবা/মুশারাকা হলে, শতকরা কত ভাগ লাভ পাবেন
capitalReturnTermDays   // চুক্তি অনুযায়ী কত দিনে মূলধন ফেরত দিতে হবে (nullable)
profitPayoutCycle       // দৈনিক / মাসিক / চুক্তিভিত্তিক
notes                   // চুক্তির বিস্তারিত শর্ত (free text)
```
> "নগদ ঋণ" (cash_loan) মানে শুধু মূলধন ফেরত, লাভ ভাগ নেই। "মুদারাবা/মুশারাকা" মানে profitSharePercent অনুযায়ী লাভ ভাগ হবে। "goods_in_kind" মানে তিনি সরাসরি পণ্য দিয়েছেন, টাকা না।

### Purchase / মোকাম-ট্রিপ (একদিনের বাজার এন্ট্রি)
```
id, date, transportCost, otherCosts[] (বিবরণ+টাকা), cashReturned (ফেরত/চেঞ্জ)
items: PurchaseItem[]   // একই ট্রিপে একাধিক দোকান/পণ্য থাকতে পারে
```
এটাই আগের "নগদ" ফর্ম — কিন্তু এখন এক ট্রিপে একাধিক আইটেম, প্রতিটার **আলাদা fund source** থাকবে।

### PurchaseItem
```
id, purchaseId, shopName, productId (বা নতুন প্রোডাক্ট তৈরি), qty, unitPrice
fundSource: { type: "shop" | "investor", investorId?: id }
isInKind: bool   // true হলে এই আইটেমের জন্য কোনো cash expense হয়নি, ইনভেস্টর সরাসরি পণ্য দিয়েছেন
```

### Product / Stock item
```
id, name, category (Book/Date/Attar/Topi/...), photo
costPrice (unit), suggestedSellPrice
qty
fundSource: { type: "shop" | "investor", investorId? }   // PurchaseItem থেকে ইনহেরিট
isRentable: bool   // শুধু Book ক্যাটাগরির জন্য true হতে পারে
```

### Sale (দৈনিক বিক্রি)
```
id, productId, qty, actualSellPrice (বিক্রির সময় কমবেশি করা যায়), date
customerId (nullable, walk-in হলে blank)
paymentStatus: full_cash | partial | full_due
```

### Due (বাকি)
```
id, customerId, sourceType: sale | rent
sourceId, originalAmount, paidAmount, promisedDays (কত দিনে দিবে বলেছে)
status: pending | partially_paid | paid
```

### Customer
```
id, name, address, contact
suspicionFlag: bool   // ভাড়া ফেরত না দেয়া/সন্দেহজনক হলে
isBlocked: bool        // চুরি হিসেবে গণ্য হলে
```
> "ক্রেতা / অর্ডার দাতা / ভাড়াটে / বাকি" — এগুলো আলাদা টেবিল না, একই Customer-এর উপর Sale/Rent/Due রেকর্ড থেকে ফিল্টার করা ভিউ।

### RentPricingTier (কনফিগারযোগ্য, ডিফল্ট নিচে দেওয়া)
```
maxPages, days, price
```
| পৃষ্ঠা | দিন | ভাড়া |
|---|---|---|
| ৫০ | ৫ | ৳৫ |
| ১০০ | ১০ | ৳১০ |
| ২০০ | ১৫ | ৳২০ |
| ৩০০ | ২০ | ৳৩০ |

### RentTransaction (বই ভাড়া)
```
id, bookProductId, customerId
startDate, dueDate (tier থেকে অটো-ক্যালকুলেট)
deposit (জামানত)
extraDayCharge, damageCharge (nullable, ফেরতের সময় হিসাব হবে)
status: active | returned | overdue | treated_as_stolen
```
ফেরত না দিলে ও overdue বহুদিন চললে → status = treated_as_stolen → Customer.isBlocked = true

### Expense
```
id, category: monthly_rent | daily_other
amount, date, description
```
> নিয়ম: এই খরচ **বেচা-কেনা থেকে আসা ক্যাশ থেকেই দেওয়া হয়** — অর্থাৎ Total Cash থেকে বিয়োগ হবে, কোনো ইনভেস্টরের আলাদা ফান্ড থেকে না।

### InvestorRepayment
```
id, investorId, amount, date
type: capital_return | profit_share
```

---

## ২. বিজনেস লজিক — মডিউল অনুযায়ী

### ক) মোকাম/Purchase এন্ট্রি
- একদিনের ট্রিপে একাধিক PurchaseItem, প্রতিটার fundSource আলাদা হতে পারে (কিছু দোকানের টাকায়, কিছু ইনভেস্টর-১-এর টাকায়)
- **সেই দিনের রিকনসিলিয়েশন:** মোট বের হওয়া টাকা = Σ(item.qty × item.unitPrice, শুধু isInKind=false গুলো) + transportCost + Σ(otherCosts) − cashReturned
  - এই টোটাল fund-source অনুযায়ী ভাগ করে (কত শপের টাকা, কত কোন ইনভেস্টরের টাকা) মিলিয়ে দেখা যাবে বাস্তবে যে টাকা নিয়ে বের হয়েছিলেন তার সাথে মিলছে কিনা
- `isInKind: true` আইটেমের জন্য **কোনো Cash deduction হবে না**, কোনো Expense/Purchase-cash এন্ট্রি হবে না — শুধু Stock-এ যোগ হবে, ইনভেস্টরের নামে ট্যাগ হয়ে, তার দেওয়া দামে ভ্যালুয়েশন সহ
- প্রতিটা PurchaseItem সেভ হলে Product.qty বাড়বে, costPrice সেট/আপডেট হবে

### খ) Stock পেজ
- আইটেম অনুযায়ী ফিল্টার (ক্যাটাগরি) ও ইনভেস্টর অনুযায়ী ফিল্টার — দুটোই fundSource থেকে আসবে
- প্রতিটা ক্যাটাগরির জন্য দেখানো যাবে: মোট cost value, সম্ভাব্য sale value (qty × suggestedSellPrice), সম্ভাব্য profit
- বেশি বিক্রি হওয়া বনাম কমে যাওয়া পণ্য — Sale রেকর্ড থেকে qty movement ট্র্যাক করে বের করতে হবে

### গ) দৈনিক বিক্রি — এন্ট্রি UI ফ্লো (আপডেটেড)

**ধাপ ১ — ক্যাটাগরি-ভিত্তিক সার্চ (আগের চেয়ে বেশি নির্দিষ্ট):**
- উপরে ক্যাটাগরি চিপ (সব / Book / Date / Attar / Topi ...) — একটা সিলেক্ট করলে সার্চ সেই ক্যাটাগরির মধ্যেই সীমাবদ্ধ থাকবে
- এর নিচে সার্চ বক্সে টাইপ করলে স্টক থেকে অটো-সাজেস্ট আসবে (শুধু সিলেক্ট করা ক্যাটাগরির পণ্য), ফলে একই নামের পণ্য বিভিন্ন ক্যাটাগরিতে থাকলেও ভুল বাছাই হওয়ার সুযোগ কমবে

**ধাপ ২ — পরিমাণ ও দাম, দুটোই এডিটেবল:**
- পণ্য সিলেক্ট করার পর `qty` ও `unitPrice` দুটো ফিল্ডই ডিফল্ট ভ্যালু (qty=1, price=suggestedSellPrice) নিয়ে আসবে, কিন্তু দুটোই ম্যানুয়ালি বদলানো যাবে
- `profit = (actualSellPrice − product.costPrice) × actualQty` — যেকোনো পরিবর্তনে লাইভ রিক্যালকুলেট হবে

**ধাপ ৩ — লেনদেনের ধরন বাছাই (Transaction Type Router):**
তিনটা অপশন (সেগমেন্টেড বাটন/ট্যাবের মতো): **নগদ | বাকি | ভাড়া** — যেটা বাছাই করবেন সেটাই সেই এন্ট্রিকে সঠিক ফ্লো-তে নিয়ে যাবে:

| অপশন | কী হবে |
|---|---|
| **নগদ** | সরাসরি Sale সেভ হবে, `paymentStatus: full_cash`, `paymentMethod` (নগদ/মোবাইল ব্যাংকিং/ব্যাংক) বেছে নেওয়ার অপশন আসবে |
| **বাকি** | Sale সেভ হবে কিন্তু `paymentStatus: full_due` বা `partial` (যদি আংশিক নগদ নেন), সাথে ইনলাইনে customerId + `promisedDays` চাইবে — সেভ হলে একইসাথে Due এন্ট্রি অটো-তৈরি হবে |
| **ভাড়া** | এই অপশনটা শুধু `isRentable: true` পণ্যে (Book ক্যাটাগরি) দেখাবে — সিলেক্ট করলে এটা আর Sale থাকবে না, বরং RentTransaction ফ্লোতে চলে যাবে (তখন days/deposit ইত্যাদি জিজ্ঞেস করবে) — Stock থেকে permanently কমবে না, `availableCopies` কমবে |

- সেভ হলে (নগদ/বাকি ক্ষেত্রে): Product.qty কমবে → Investor পেজ আপডেট হবে (তার sale/profit বাড়বে) → সারসংক্ষেপ পেজ আপডেট হবে
- Customer নতুন হলে অটো-ক্রিয়েট হয়ে Customer পেজে যোগ হবে
- এই profit product-এর fundSource অনুযায়ী owner (shop) বা নির্দিষ্ট investor-এর নামে জমা হবে

### ঘ) লাভ হিসাবের দুইটা স্তর (এইটা সবচেয়ে গুরুত্বপূর্ণ)

**স্তর ১ — প্রতি বিক্রির গ্রস প্রফিট** (per-sale, per-investor payout-এর জন্য):
```
grossProfit = actualSellPrice − costPrice   (per unit)
```
এটাই বর্তমানে ইনভেস্টরকে (যেমন আতর-ভাই) তার পণ্যের দাম + লাভের অংশ ফেরত দিতে ব্যবহার হচ্ছে — কোনো ভাড়া/খরচ বিয়োগ ছাড়া, কারণ আলাদাভাবে ভাড়া ভাগ করলে তার লাভ প্রায় শূন্য হয়ে যায়।

**স্তর ২ — দোকানের প্রকৃত নিট লাভ** (সামগ্রিক ব্যবসার স্বাস্থ্য বোঝার জন্য, মূলধন ফেরত/সামগ্রিক লাভ-ভাগের সিদ্ধান্তের জন্য):
```
netProfit = Σ(grossProfit সব বিক্রি থেকে) − Σ(Expense: monthly_rent + daily_other)
```
এই `netProfit`-টাই আসল হিসাব যেটা দেখে বোঝা যাবে ব্যবসায় সত্যিকারের কত লাভ থাকছে, এবং investor repayment-এর সিদ্ধান্ত এখান থেকেই নিতে হবে — যদিও **per-investor payout স্তর ১ দিয়েই হয়**।

> এজেন্টকে দুইটা আলাদা ফাংশন/মেথড বানাতে বলবেন: `calculateGrossProfitPerSale()` আর `calculateShopNetProfit()` — মিশিয়ে ফেললে হিসাব ঘুলিয়ে যাবে।

### ঙ) Investor পেজ
প্রতি ইনভেস্টরের জন্য:
- **মোট বিনিয়োগ** = cash দিয়েছেন এমন টাকা + in-kind পণ্যের valuation যোগফল
- **বর্তমান স্টক মূল্য (তার নামে)** = Σ(তার fundSource-এর Product.qty × costPrice) — এখনো বিক্রি হয়নি এমন
- **কেনা** = Σ(তার fundSource দিয়ে করা PurchaseItem-এর টাকা, শুধু cash অংশ)
- **বিক্রি** = Σ(তার পণ্য থেকে হওয়া Sale-এর actualSellPrice × qty)
- **লাভ (তার ভাগ)** = Σ(grossProfit) × profitSharePercent (যদি cash_loan হয় তাহলে ০, পুরো মূলধনই ফেরতযোগ্য)
- **বাকি ব্যালেন্স / ফেরত পাওনা** = মোট বিনিয়োগ − Σ(InvestorRepayment, type=capital_return) [+ অপরিশোধিত profit_share থাকলে তাও দেখানো যায়]
- **কবে দিতে হবে** = `capitalReturnTermDays` ও `profitPayoutCycle` অনুযায়ী পরবর্তী পেমেন্ট তারিখ ক্যালকুলেট করে সারসংক্ষেপ/হোম পেজে reminder আকারে দেখানো
- ইনভেস্টর যদি নিজে কোনো নগদ/বাকি নেন (যেমন অগ্রিম টাকা তুলে নিলেন), সেটাও এখানে আলাদা লেনদেন হিসেবে যোগ হবে (InvestorRepayment বা নতুন `InvestorTransaction` টাইপ)

### চ) Expense পেজ (৩টা সেকশন)
1. **মাসিক ভাড়া ও অন্যান্য খরচ** — বেচাকেনার ক্যাশ থেকেই কাটে, Total Cash কমায়
2. **কেনা (মোকাম এন্ট্রি)** — উপরে বর্ণিত Purchase/PurchaseItem লজিক, fund source অনুযায়ী
3. **ইনভেস্টর পরিশোধ তালিকা** — সব InvestorRepayment এন্ট্রির লিস্ট (কাকে কবে কত দেওয়া হলো)

### ছ) Due পেজ
- **আজকের বাকি / মাসিক বাকি / মোট বাকি** — Due.remainingAmount থেকে ফিল্টার করে যোগফল
- প্রতিটা Due-তে `promisedDays` অনুযায়ী reminder — owner, customer (এবং যদি সেই পণ্য কোনো ইনভেস্টরের হয়, সেই investor)-কেও জানানো
- বাকি পরিশোধ হলে: Due.status আপডেট → সারসংক্ষেপ পেজ, Customer পেজ, (প্রযোজ্য হলে) Investor পেজ — সব জায়গায় রিফ্লেক্ট করবে

### জ) বই ভাড়া (Rent)
- ভাড়া দেওয়ার সময় বইয়ের pageCount অনুযায়ী RentPricingTier থেকে days ও price অটো-সাজেস্ট হবে (ম্যানুয়াল ওভাররাইড করা যাবে)
- জামানত (deposit) ও ঠিকানা — **Rent-issue ফর্মেই** নেওয়া হবে (Customer তৈরির সাধারণ ফর্মে না) — কারণ এটা শুধু বই-ভাড়ার ঝুঁকি সামলাতে দরকার, সাধারণ ক্রেতা/অর্ডার-দাতার জন্য অপ্রাসঙ্গিক। `isSuspicious` true থাকা কাস্টমারের জন্য এই দুইটা ফিল্ড বাধ্যতামূলক করা যেতে পারে
- ফেরতের সময়: `extraDayCharge` (দেরি হলে) ও `damageCharge` (ক্ষতি হলে) যোগ হয়ে হিসাব হবে
- নির্দিষ্ট সময়ে ফেরত না দিলে ও ফলোআপেও সাড়া না দিলে → status = treated_as_stolen, Customer.isBlocked = true
- Customer-এ `suspicionFlag` টিক দেওয়া থাকলে বারবার owner-কে reminder দেখাবে (follow-up প্রয়োজন)

**বই ফেরত (Return) ফ্লো — উদাহরণ:**
1. "বর্তমান ভাড়া" লিস্ট থেকে টিক দিয়ে সিলেক্ট — বইয়ের নাম, কাস্টমার, শুরুর তারিখ, নির্ধারিত ফেরত-তারিখ অটো দেখাবে
2. প্রকৃত ফেরত-তারিখ (ডিফল্ট আজ)
3. `অতিরিক্ত দিন = max(0, প্রকৃত তারিখ − নির্ধারিত তারিখ)` — সিস্টেম নিজে হিসাব করবে
4. `extraDayCharge` প্রতি-দিন রেট (Settings-এ কনফিগারযোগ্য) দিয়ে অটো-সাজেস্ট, ম্যানুয়াল ওভাররাইড করা যাবে
5. `damageCharge` — ক্ষতি থাকলে ম্যানুয়ালি বসাবেন, নাহলে ০
6. মোট প্রদেয় = বেসিক ভাড়া + extraDayCharge + damageCharge − জামানত সমন্বয়
7. পুরো/আংশিক পরিশোধ — আংশিক হলে বাকিটা Due-তে (sourceType: rent) যাবে
8. সেভ হলে: `RentTransaction.status = returned`, `Product.availableCopies += 1`

### ঝ) সারসংক্ষেপ / Dashboard
```
Total Cash = Σ(Sale cash portion) + Σ(Due payments received) + Σ(Rent income)
           − Σ(Purchase cash portion, isInKind=false)
           − Σ(Expense: monthly_rent + daily_other)
           − Σ(InvestorRepayment)
```
এই টোটালটা প্রতিদিন শেষে বাস্তবে হাতে থাকা ক্যাশের সাথে মিলে যাওয়া উচিত — এটাই মূল স্যানিটি-চেক।

**তারিখ-ভিত্তিক (Day) ভিউ ডিফল্ট, ক্লিকে All-time ভিউ:**
- স্ক্রিনশটে যে ক্যালেন্ডার আইকন (📅) আছে, সেটাই এই ফিচারের এন্ট্রি পয়েন্ট
- ডিফল্টভাবে Dashboard-এর প্রতিটা কার্ড (মোট নগদ, স্টকের মূল্য, মোট কেনা, মোট বিক্রি, নিট মুনাফা ইত্যাদি) সিলেক্ট করা তারিখের (ডিফল্ট আজ) মধ্যে যা ঘটেছে শুধু তাই দেখাবে — ঐ দিনের PurchaseItem, Sale, Due payment, RentTransaction, Expense সব `date` ফিল্ড দিয়ে ফিল্টার হয়ে
- স্টকও সেদিনের যোগ হওয়া স্টকের সাথে মিলবে (সেদিন বিক্রি হয়ে যাওয়া আইটেম বাদ)
- কোনো কার্ডে ট্যাপ করলে সেই একই কার্ড date-filter সরিয়ে **All-time** টোটাল দেখাবে
- **ইমপ্লিমেন্টেশন নোট:** আলাদা "daily snapshot" টেবিল না রেখে, একই ক্যালকুলেশন ফাংশনে `dateRange` প্যারামিটার দিয়ে Day view ও All-time view — দুটোই একই লজিক দিয়ে সার্ভ করা ভালো (কোড ডুপ্লিকেশন এড়াতে)

---

## ৩. নতুন সংযোজন (এই রাউন্ডে যোগ হলো)

### QuickCapture (কুইক সেল / দ্রুত নোট)
মোবাইলের নিজস্ব ভয়েস রেকর্ডার ও নোট/স্ক্রিনশট ফিচার ব্যবহার করে দ্রুত একটা রেকর্ড রাখা, পরে সময় করে ফরমাল এন্ট্রি (Sale/Purchase/Expense) বানানোর জন্য।
```
QuickCapture {
  id, type: voice_note | photo_note
  fileUri            // ডিভাইসে সেভ হওয়া ভয়েস/ছবির পাথ
  createdAt
  status: pending | converted
  convertedToType, convertedToId (nullable)   // যখন এটা থেকে আসল Sale/Purchase/Expense বানানো হয়
}
```
- হোম পেজে একটা ফ্লোটিং বাটন দিয়ে সরাসরি ভয়েস রেকর্ড/নোট নেওয়া যাবে — কোনো ফর্ম ফিলাপ ছাড়াই
- "পেন্ডিং কুইক ক্যাপচার" একটা লিস্টে জমা থাকবে, যেখান থেকে ক্লিক করে সেটাকে আসল এন্ট্রিতে রূপান্তর করা যাবে (মেনুর "দ্রুত নোট" মডিউলটাই এই ফিচারের হোম)

### PaymentMethod — সব টাকা-লেনদেনে যোগ হবে
নগদ ছাড়াও মোবাইল ব্যাংকিং (বিকাশ/নগদ ইত্যাদি) বা ব্যাংক ট্রান্সফারে টাকা আসা/যাওয়া হতে পারে। তাই যেকোনো টাকার এন্ট্রিতে (Sale payment, Due payment, Purchase payment, Expense, InvestorRepayment) একটা কমন ফিল্ড যোগ হবে:
```
paymentMethod: cash | mobile_banking | bank_transfer
```
**ড্যাশবোর্ড কার্ডে প্রভাব:** "মোট নগদ" কার্ডকে এখন তিনটা সাব-ব্যালেন্সে ভাগ করে হিসাব রাখতে হবে —
```
cashBalance     = Σ(paymentMethod=cash এন্ট্রিগুলোর নিট প্রভাব)
mobileBankingBalance = Σ(paymentMethod=mobile_banking এন্ট্রিগুলোর নিট প্রভাব)
bankBalance     = Σ(paymentMethod=bank_transfer এন্ট্রিগুলোর নিট প্রভাব)

Total Available Funds = cashBalance + mobileBankingBalance + bankBalance
```
"মোট নগদ" কার্ডে ট্যাপ করলে এই তিনটা ব্রেকডাউন দেখাবে (যেমন Day/All-time টগলের মতোই প্যাটার্ন) — এতে হাতের নগদ, বিকাশ/নগদ ব্যালেন্স, আর ব্যাংক ব্যালেন্স আলাদা করে মিলিয়ে দেখা যাবে।

### Order (কাস্টমার → অর্ডার দাতা)
```
Order {
  id, customerId
  itemDescription      // কী চান
  requestedDate, neededByDate   // কবে চেয়েছেন, কবে লাগবে
  status: pending | fulfilled | cancelled
  fulfilledDate (nullable)   // শেষ পর্যন্ত নিয়েছেন কিনা তার প্রমাণ
}
```
Customer পেজের "অর্ডার দাতা" ট্যাব এই Order টেবিল থেকে ফিল্টার করা ভিউ — status অনুযায়ী পেন্ডিং/সম্পন্ন/বাতিল দেখা যাবে।

### Fixed Asset — দুইভাবে যোগ করার ব্যবস্থা
```
FixedAsset {
  id, name, value, dateAcquired
  source: { type: shop_cash_purchase | converted_from_stock, productId?: id }
}
```
1. **সরাসরি কেনা** — দোকানের ক্যাশ থেকে সরাসরি একটা ফিক্সড এসেট কেনা (যেমন শোকেস, ফ্যান) → Cash কমবে, FixedAsset-এ যোগ হবে
2. **স্টক থেকে কনভার্ট** — বিক্রির জন্য রাখা কোনো পণ্যকে ফিক্সড এসেট বানানো (যেমন একটা আতরের শোপিস বোতল আর বিক্রি না করে ডেকোরেশনে রাখা) → Product.qty থেকে বিয়োগ হবে, FixedAsset-এ productId রেফারেন্স সহ যোগ হবে, কোনো নতুন Cash movement হবে না

### প্রাইসিং রেকমেন্ডেশন ইঞ্জিন (গুরুত্বপূর্ণ — বিক্রয়মূল্য সাজেশন)

আপনি যা চেয়েছেন তা হলো: কস্ট প্রাইস লেখার পর সিস্টেম এমন একটা বিক্রয়মূল্য সাজেস্ট করবে যাতে দোকান ভাড়া, আপনার বেতন, মোকাম ট্রিপের খরচ, আর ইনভেস্টরকে দেওয়া লাভের ভাগ — সব মিলিয়ে সামঞ্জস্য থাকে।

```
OverheadSettings (Settings পেজে কনফিগারযোগ্য) {
  monthlyShopRent
  monthlyOwnerSalary
  averageMonthlyTripCost     // MokamEntry-র transportCost+otherCosts থেকে গত কয়েক মাসের গড়, অথবা ম্যানুয়াল
  estimatedMonthlySalesRevenue   // গত মাসের প্রকৃত বিক্রি থেকে অটো, অথবা ম্যানুয়াল অনুমান
}

monthlyOverhead = monthlyShopRent + monthlyOwnerSalary + averageMonthlyTripCost
overheadMarkupPercent = monthlyOverhead ÷ estimatedMonthlySalesRevenue
```

**পণ্যের জন্য সাজেস্টেড সেল প্রাইস (costPrice এন্ট্রির সাথে সাথেই দেখাবে):**
```
// পণ্যটা যদি কোনো ইনভেস্টরের (profitSharePercent সহ) হয়:
requiredMargin = overheadMarkupPercent ÷ (1 − investor.profitSharePercent)

// পণ্যটা দোকানের নিজের হলে (fundSource = shop):
requiredMargin = overheadMarkupPercent

suggestedSellPrice = costPrice × (1 + requiredMargin)
```

**কেন এই ফর্মুলা কাজ করে:** যেহেতু ইনভেস্টরের পণ্যের গ্রস প্রফিট থেকে তার অংশ (`profitSharePercent`) কেটে নেওয়া হয়, তাই দোকানের ভাগে (overhead cover করার জন্য) যথেষ্ট থাকতে হলে মার্জিনটা বেশি রাখতে হবে — ভাগ করার আগে (÷ (1 − শেয়ার%)) দিয়ে সেটা কম্পেনসেট করা হচ্ছে। এভাবে আপনি সাজেশন দেখেই বুঝবেন কোন পণ্যে কম মার্জিনে বিক্রি করলে ক্ষতি হবে, কোনটায় ঠিক আছে। সাজেশনটা সবসময় ম্যানুয়ালি ওভাররাইড করা যাবে।

---

## ৪. Data Integrity Rules (আপডেটেড)

1. প্রতিটা PurchaseItem/Sale-এর একটা নির্দিষ্ট `fundSource` থাকতেই হবে (nullable না) — নাহলে investor attribution ভুল হবে
2. `isInKind: true` আইটেম কখনো cash ledger-এ প্রভাব ফেলবে না, শুধু stock ও investor-valuation-এ যাবে
3. grossProfit (per-sale) আর netProfit (shop-wide) — দুটো আলাদা ফাংশন, কোথাও মিশ্রিত করা যাবে না
4. Rent-এর ক্ষেত্রে বই বিক্রি হয় না — `Product.qty` স্থায়ীভাবে কমবে না, বরং `availableCopies` টেম্পোরারি কমবে যতক্ষণ RentTransaction active থাকে
5. Due/Repayment paid হলে অবশ্যই সংশ্লিষ্ট সব পেজ (Dashboard, Customer, Investor) synchronously আপডেট হতে হবে — event-driven বা recalculate-on-read পদ্ধতি ব্যবহার করুন

---

## ৬. পুরনো হিসাব নিষ্পত্তি (Legacy Settlement) — আব্বার ৫ বছরের খাতার হিসাব

দোকান আগে থেকেই আব্বার বিনিয়োগে ৫ বছর ধরে চলছিল, হিসাব খাতায় রাখা ছিল, অ্যাপে গ্রানুলার (প্রতিটা কেনা/বিক্রি) এন্ট্রি নেই। তাই এটা সাধারণ Investor ফ্লো দিয়ে ট্র্যাক করা যাবে না — একবারের জন্য একটা **সামারি এন্ট্রি (lump-sum)** দরকার, তারপর থেকে অ্যাপ নতুন করে সব ট্র্যাক করবে।

```
LegacySettlement {
  id, investorId              // আব্বা
  totalHistoricalInvestment    // খাতা থেকে হিসাব করা মোট বিনিয়োগ
  totalAlreadyReturned         // ইতিমধ্যে যা ফেরত দেওয়া হয়েছে (যদি থাকে)
  netSettlementAmount          // এখন যা বুঝিয়ে দিতে হবে (হিসাব করে)
  settlementDate
  notes                        // খাতার রেফারেন্স/সারাংশ, ফ্রি-টেক্সট
  status: pending | settled
}
```

**ফ্লো:**
1. অ্যাপে আব্বাকে Investor হিসেবে যোগ করার সময় একটা "পুরনো হিসাব আছে?" টগল থাকবে — হ্যাঁ হলে LegacySettlement ফর্ম আসবে (উপরের ফিল্ডগুলো, একবারই পূরণ করার জন্য)
2. এই এন্ট্রিটা normal MokamEntry/Sale ইতিহাসের সাথে মিশবে না — এটা শুধু একটা "ওপেনিং/ক্লোজিং ব্যালেন্স" নোট হিসেবে থাকবে, যাতে ভবিষ্যতে দরকার পড়লে রেফারেন্স হিসেবে দেখা যায়
3. একবার `status: settled` হয়ে গেলে, আব্বার Investor প্রোফাইল **শূন্য থেকে (fresh start)** নতুন করে ট্র্যাকিং শুরু করবে — অর্থাৎ তিনি ভবিষ্যতে আবার বিনিয়োগ করলে সেটা normal Investor/MokamEntry ফ্লো দিয়েই যাবে
4. আম্মু ও অন্য নতুন ইনভেস্টররা (যেমন আতর-ভাই) — তাদের জন্য কোনো LegacySettlement লাগবে না, তারা প্রথম থেকেই normal ফ্লোতে শুরু করবেন

এভাবে পুরনো ৫ বছরের এলোমেলো হিসাব আর নতুন অ্যাপের পরিষ্কার ট্র্যাকিং — দুটো আলাদা থাকবে, একটা আরেকটাকে জটিল করবে না।

### প্রাইসিং ইঞ্জিন বুটস্ট্র্যাপ (আগের প্রশ্নের উত্তর)

যেহেতু `estimatedMonthlySalesRevenue`-এর কোনো ধারণা নেই, শুরুতে এটা **auto-bootstrap** হবে:
- প্রথম মাসে মার্কআপ-সাজেশন ফিচার সাময়িকভাবে বন্ধ/হাইড থাকবে (ভুল ডেটা দিয়ে ভুল সাজেশন এড়াতে)
- মাস শেষে সিস্টেম নিজে প্রকৃত সেই মাসের Total Sale থেকে `estimatedMonthlySalesRevenue` সেট করে দেবে
- দ্বিতীয় মাস থেকে সাজেশন চালু হবে, প্রতি মাস শেষে অটো-রিফ্রেশ হবে (আগের মাসের প্রকৃত ডেটা দিয়ে), ম্যানুয়াল ওভাররাইড সবসময় সম্ভব



## ৭. এখনো যা কনফার্ম করা দরকার

- ~~profitSharePercent প্রতি ইনভেস্টরে আলাদা কিনা~~ ✅ কনফার্মড — প্রতিটা ইনভেস্টরের জন্য আলাদা, ইতিমধ্যে Investor entity-তে তাই মডেল করা আছে
- ~~Sale entry ফর্মের এক্সাক্ট UI ফিল্ড~~ ✅ কনফার্মড — ক্যাটাগরি-ফিল্টার্ড সার্চ, এডিটেবল qty/price, নগদ/বাকি/ভাড়া রাউটার (গ) সেকশনে বিস্তারিত)
- ~~বই ফেরত (Rent Return) স্ক্রিনের ডিজাইন~~ ✅ কনফার্মড — উদাহরণ ফ্লো "জ" সেকশনে যোগ করা হয়েছে
- ~~Customer পেজে ঠিকানা/জামানত এন্ট্রি ঠিক কোথায় হবে~~ ✅ কনফার্মড — Rent-issue ফর্মেই নেওয়া হবে, সাধারণ Customer তৈরির ফর্মে না
- ~~estimatedMonthlySalesRevenue প্রথম মাসে কীভাবে সেট হবে~~ ✅ কনফার্মড — auto-bootstrap, প্রথম মাসে ফিচার হাইড থেকে পরের মাস থেকে অটো-চালু

**সব খোলা প্রশ্ন এখন রিজলভড। ডকুমেন্টটা এজেন্টকে দেওয়ার জন্য প্রস্তুত।**
