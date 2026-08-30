১৬. নতুন অ্যাপে সরাসরি টেস্ট করে পাওয়া সমস্যার তালিকা (কোড চেক করে কনফার্মড)

এই তালিকাটা আপনার হাতে-কলমে যাচাই আর কোড রিভিউ মিলিয়ে তৈরি — প্রতিটা আইটেম কোড দেখে নিশ্চিত করা হয়েছে, অনুমান না।

১৬.১ প্রোডাক্ট যোগ করার ফর্ম (Catalog)
সংখ্যা (qty) দেওয়ার ফিল্ড নেই — নতুন প্রোডাক্ট তৈরি হয় সবসময় qty: 0 দিয়ে (catalog_controller.dart)। স্টকে সংখ্যা যোগ করতে হলে আলাদা "Purchase Entry" স্ক্রিনে যেতে হয় — পুরনো অ্যাপে যেটা এক ধাপেই (নাম+দাম+সংখ্যা) হতো, নতুনে সেটা দুই ধাপ।
ইউনিট/পরিমাপ সিস্টেম নেই — পুরনো অ্যাপে buy unit/sell unit (kg, pcs, litre ইত্যাদি) ও কনভার্শন ফ্যাক্টর ছিল; নতুনে শুধু একটা ফ্ল্যাট cost price/sell price, কোনো ইউনিট সিলেকশন নেই।
(Cost price ও Sell price ফিল্ড দুটোই আছে এবং কাজ করে — এটা সমস্যা না)
১৬.২ ছবি (Photo) — সম্পূর্ণ ফিচার অনুপস্থিত
পুরো কোডবেসে image_picker, imagePath, বা কোনো ছবি-সংক্রান্ত কোড কোথাও নেই।
Product, Customer, FixedAsset — কোনো এনটিটিতেই ছবির ফিল্ড নেই। পুরনো অ্যাপে এই তিন জায়গাতেই ক্যামেরা দিয়ে ছবি তোলা যেত।
১৬.৩ প্রতিটা পেজে দোকানের পরিচিতি নেই
Dashboard/Daily Sales/Stock/Dues/Customers — সবগুলোর AppBar-এ শুধু প্লেইন টেক্সট টাইটেল, দোকানের লোগো নেই, নাম নেই, আজকের তারিখও দেখানো হয় না।
shop_logo.dart widget কোডে আছে, কিন্তু শুধু Drawer আর Sign-in স্ক্রিনে ব্যবহৃত — এই ৫টা মূল স্ক্রিনে না।
১৬.৪ নির্দিষ্ট তারিখ বাছাইয়ের ক্যালেন্ডার আইকন নেই — নিজেদের স্পেক থেকেও পিছিয়ে
Dashboard-এ শুধু "Day view / All-time view" টগল চিপ আছে — কোনো ক্যালেন্ডার আইকন বা ডেট-পিকার নেই।
"Day" মানে সবসময় শুধু আজকের দিন — অতীতের কোনো নির্দিষ্ট তারিখ বেছে সেদিনের হিসাব দেখার উপায় নেই।
এটা business_logic.md §ঝ-এর নিজের স্পেক থেকেও পিছিয়ে আছে — সেখানে স্পষ্ট লেখা "ক্যালেন্ডার আইকন (📅)" থাকার কথা এই ফিচারের এন্ট্রি পয়েন্ট হিসেবে।
ব্যবহারকারীর কনফার্মেশন: বর্তমান "Today / All-time" টগল অপশনটা রেখে দিতে হবে — এটা বাদ দেওয়া যাবে না। এর পাশাপাশি ক্যালেন্ডার আইকন দিয়ে নির্দিষ্ট (অতীতের) তারিখ বেছে সেদিনের হিসাব দেখার সুবিধাও যোগ করতে হবে — দুটোই একসাথে থাকবে, একটা আরেকটার বদলে না।
১৬.৫ Quick Capture বাটন ফ্রন্ট পেজে ফ্লোটিং না
Quick Capture-এর নিজস্ব FloatingActionButton আছে, কিন্তু শুধু তার নিজের স্ক্রিনে (ড্রয়ার থেকে আলাদা গিয়ে খুলতে হয়)।
Dashboard/front page-এ কোনো ফ্লোটিং বাটন নেই — পুরনো অ্যাপে Overview পেজ থেকেই সরাসরি এক ট্যাপে Quick Capture খোলা যেত।
১৬.৬ Daily Sales স্ক্রিনে ক্র্যাশ/রেড এরর স্ক্রিন — কনফার্মড, রুট কজ পাওয়া গেছে
Daily Sales পেজ খুললে GetX-এর একটা রেড ডিবাগ এরর স্ক্রিন দেখা যায়: "the improper use of a GetX has been detected"
কারণ: daily_sales_screen.dart-এ প্রোডাক্ট-সার্চ (Autocomplete) অংশটা Obx(() => Row(...))-এর ভেতরে মোড়ানো, কিন্তু controller.products (observable) আসলে পড়া হচ্ছে Autocomplete-এর optionsBuilder ক্লোজারের ভেতরে — যেটা Obx-এর build-এর সময় সরাসরি চলে না, বরং পরে ইউজার টাইপ করলে আলাদাভাবে কল হয়
ফলে Obx তার নিজের build-এর সময় কোনো observable dependency খুঁজে পায় না, আর GetX-এর সেফটি-চেক এই এরর ছুঁড়ে দেয়
ফিক্স: ওই Row/Autocomplete-কে Obx() দিয়ে মোড়ানোর দরকারই নেই (কারণ ভেতরে কিছুই সরাসরি reactive re-render দরকার করে না) — Obx() সরিয়ে ফেললেই এই এরর চলে যাওয়ার কথা। এক্স্যাক্ট কোড-ফিক্স:
dart
// আগে (ভুল) — daily_sales_screen.dart, _SaleFormBodyState.build()
Obx(
  () => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Autocomplete<Product>(/* ... */)),
      if (PlatformCapabilities.detect().hasCamera)
        IconButton(
          tooltip: 'scanBarcodeTitle'.tr,
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => _scanBarcode(context),
        ),
    ],
  ),
),

// পরে (ঠিক) — শুধু Obx() র‍্যাপার সরিয়ে সাধারণ Row রাখা
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: Autocomplete<Product>(/* অপরিবর্তিত */)),
    if (PlatformCapabilities.detect().hasCamera)
      IconButton(
        tooltip: 'scanBarcodeTitle'.tr,
        icon: const Icon(Icons.qr_code_scanner),
        onPressed: () => _scanBarcode(context),
      ),
  ],
),

Autocomplete-এর ভেতরের optionsBuilder/onSelected/fieldViewBuilder অপরিবর্তিত রাখতে হবে — শুধু বাইরের Obx(() => ...) র‍্যাপারটা সরালেই হবে।

উপরের ১৬.১–১৬.৫ সবগুলো সরাসরি সোর্স কোড পড়ে কনফার্ম করা হয়েছে (১৬ আগস্ট ২০২৬ পর্যন্ত আপলোড করা inventory-main.zip অনুযায়ী)।

১৬.৭ Net Profit/Net Loss লেবেল বদলায় না
সংখ্যা লস হলে রং ঠিকই লাল হয় (highlightNegative: true)
কিন্তু লেবেল টেক্সট সবসময় "Net Profit"/"নিট মুনাফা" থেকে যায় — পুরনো অ্যাপে যেমন লস হলে লেবেলও "Net Loss"/"নিট ক্ষতি"-তে বদলে যেত, নতুনে সেটা হয় না
অনুবাদ ফাইলে netLoss/নিট ক্ষতি স্ট্রিং আছে ঠিকই, কিন্তু Dashboard স্ক্রিনের কোডে সেটা ব্যবহারই করা হচ্ছে না (dashboard_screen.dart)
১৬.৮ Overview পেজে কার্ড কমে যাওয়া (Expense/Due/Due Paid/Rent/Rent Paid/Total Assets/To Give Away)
dashboard_calculator.dart-এর DashboardTotals ক্লাসে মাত্র ৫টা ফিল্ড আছে: totalCash, totalSaleRevenue, totalPurchaseCashOut, netProfit, stockValue — এর বাইরে কিছুই হিসাব করা হয় না
পুরনো অ্যাপে Overview পেজে ১২টা কার্ড ছিল, নতুনে কমিয়ে ৫টা করা হয়েছে
ডেটা হারায়নি — Due/Expense/Rent/Investor প্রতিটার হিসাব নিজ নিজ আলাদা স্ক্রিনে আছে — কিন্তু Overview-এ একনজরে সারসংক্ষেপ নেই
কোডে বা business_logic.md-এ এটা ইচ্ছাকৃত সিদ্ধান্ত হিসেবে লেখা নেই, তাই ডিজাইন-সিদ্ধান্ত না বাদ পড়া তা নিশ্চিত না — ব্যবহারকারী চান বাকি কার্ডগুলো ফিরিয়ে আনা হোক
অতিরিক্ত অনুরোধ: প্রতিটা Dashboard কার্ডে ট্যাপ করলে সরাসরি সংশ্লিষ্ট পেজে (Due কার্ড → Dues স্ক্রিন, Rent কার্ড → Rent স্ক্রিন, Total Assets কার্ড → Fixed Asset স্ক্রিন, To Give Away কার্ড → Investor স্ক্রিন, ইত্যাদি) নিয়ে যাওয়ার নেভিগেশন যোগ করতে হবে — বর্তমানে কার্ডগুলো (যেগুলো আছে) শুধু তথ্য দেখায়, ট্যাপ করলে কোথাও যায় না
১৬.৯ Quick Capture-এ ছবি তোলা ও ভয়েস রেকর্ডের ব্যবস্থা চালু করা লাগবে
নোট (ফ্রি-টেক্সট) ফিচার ইতিমধ্যে কাজ করে
কিন্তু ছবি তোলা ও ভয়েস রেকর্ড করে রাখার আসল ব্যবস্থা এখনো নেই — আগে §৮.৩-এ (হ্যান্ডওভার রিপোর্ট থেকে) নিশ্চিত করা হয়েছিল যে UI-তে voice/photo অপশন দেখানো থাকলেও বাস্তবে কোনো রেকর্ডিং/ক্যাপচার হয় না, শুধু টেক্সট নোট সেভ হয়
ব্যবহারকারীর সরাসরি অনুরোধ: Quick Capture বাটনে ছবি তোলা (ক্যামেরা) ও ভয়েস অডিও হিসেবে রেকর্ড করে রাখার প্রকৃত ব্যবস্থা যোগ করতে হবে — স্পিচ-টু-টেক্সট লাগবে না, শুধু রেকর্ডিং ফাইল হিসেবে সেভ হলেই হবে (নোট ফিচার আগে থেকেই আছে, আলাদা রাখা)
১৬.১০ Stock স্ক্রিনে সরাসরি প্রোডাক্ট যোগ করার বাটন নেই
stock_screen.dart-এ কোনো FloatingActionButton নেই — প্রোডাক্ট যোগ করা যায় শুধু আলাদা catalog_screen.dart থেকে, যেখানে যেতে হয় ড্রয়ার খুলে
ব্যবহারকারীর অনুরোধ: Stock স্ক্রিনেই সরাসরি "+" বাটন (FAB) থাকা দরকার, যাতে ড্রয়ারে না গিয়ে সরাসরি প্রোডাক্ট যোগ করা যায়
১৬.১১ ক্যাটাগরি ম্যানেজমেন্ট আলাদা সেকশন/ট্যাবে সরিয়ে দেওয়া — ব্যবহারকারীর পছন্দ না
catalog_screen.dart-এ ২টা ট্যাব: একটা "Category" (যোগ/রিনেম/রিঅর্ডার), আরেকটা Products — কোডের নিজস্ব কমেন্টে লেখা আছে এটা ইচ্ছাকৃতভাবে একই controller-এ রাখা হয়েছে কারণ "আলাদা categories screen থাকার দরকার নেই" বলে মনে করা হয়েছিল, তবু বাস্তবে আলাদা ট্যাবে ভাগ করা হয়েছে
Stock স্ক্রিনে ক্যাটাগরি ও ইনভেস্টর — দুটো ফিল্টারই একই পেজে আছে (ড্রপডাউন আকারে), এটা ঠিক আছে; সমস্যা হলো ক্যাটাগরি ম্যানেজ করা (নতুন বানানো) আলাদা জায়গায়
ব্যবহারকারীর পছন্দ: পুরনো অ্যাপের মতো একই পেজে/ফ্লোতে ক্যাটাগরি ও ইনভেস্টর অনুযায়ী স্টক দেখা এবং ক্যাটাগরি যোগ করা — আলাদা সেকশন/ট্যাব না
১৬.১২ প্রোডাক্ট এন্ট্রির সময় নতুন ক্যাটাগরি যোগ করা যায় না
product_form_sheet.dart-এ ক্যাটাগরি ফিল্ড শুধু ড্রপডাউন — আগে থেকে থাকা ক্যাটাগরি থেকেই বেছে নিতে হয়, ইনলাইনে নতুন ক্যাটাগরি বানানোর কোনো "+" অপশন নেই
নতুন ক্যাটাগরি বানাতে হলে আগে Catalog স্ক্রিনের Category ট্যাবে গিয়ে বানিয়ে তারপর প্রোডাক্ট ফর্মে ফিরে আসতে হয় — পুরনো অ্যাপে প্রোডাক্ট ফর্মেই সরাসরি নতুন ক্যাটাগরি যোগ করা যেত
ব্যবহারকারীর অনুরোধ: প্রোডাক্ট যোগ করার ফর্মেই সরাসরি নতুন ক্যাটাগরি বানানোর সুবিধা ফিরিয়ে আনা
১৬.১৩ প্রোডাক্ট যোগ করার ফর্ম — সম্পূর্ণ রিডিজাইন চেকলিস্ট (ব্যবহারকারীর সরাসরি অনুরোধ)

product_form_sheet.dart বর্তমানে যা আছে: নাম, ক্যাটাগরি (ড্রপডাউন), cost price, sell price, "Funded by investor?" টগল + কন্ডিশনাল ইনভেস্টর ড্রপডাউন, "Rent a book?" টগল + কন্ডিশনাল page count, বারকোড (+স্ক্যান বাটন), SKU।

বাদ দিতে হবে:

বারকোড ফিল্ড ও স্ক্যান বাটন — দরকার নেই
SKU ফিল্ড — দরকার নেই

সহজ করতে হবে:

"Funded by investor?" টগল + আলাদা ড্রপডাউন এই দুই-ধাপের বদলে একটাই ড্রপডাউন — যেখানে প্রথম অপশন "নিজের দোকান" (Own Shop), তারপর প্রতিটা ইনভেস্টরের নাম — পুরনো অ্যাপের প্যাটার্ন
ক্যাটাগরি "বই" (Book) বাছলে rent-সংক্রান্ত ফিল্ডগুলো (isRentable + page count) স্বয়ংক্রিয়ভাবে দেখানো/চালু হওয়া উচিত — এখন সেটা ক্যাটাগরির সাথে সম্পর্কহীন একটা আলাদা ম্যানুয়াল টগল

যোগ করতে হবে (এই ফর্মে বর্তমানে নেই):

কেনার পরিমাণ (buy qty) ও কেনার দর (buy price) — নতুন প্রোডাক্ট তৈরির সময়ই এক ধাপে দেওয়া যাবে (এখন আলাদা Purchase Entry স্ক্রিনে যেতে হয়)
বর্তমানে বিক্রির জন্য কত পরিমাণ আছে তা দেখানো/এডিট করা
ইউনিট সিস্টেম: কিছু ডিফল্ট ইউনিট (pcs, kg, box, pack, litre, pair, set, dozen ইত্যাদি) প্রি-লোড করা থাকবে, এবং ব্যবহারকারী নতুন ইউনিট যোগ করলে সেটা সেভ হয়ে ভবিষ্যতের জন্য ড্রপডাউনে থেকে যাবে — পুরনো অ্যাপের buy unit/sell unit কনভার্শন সিস্টেমের ধাঁচে
প্রোডাক্টের ছবি (ক্যামেরা দিয়ে তোলা) — §১৬.২-এ আগেই চিহ্নিত

অপরিবর্তিত/ঠিক আছে:

নাম, ক্যাটাগরি নির্বাচন (ড্রপডাউন থেকে), cost price, sell price ফিল্ড — এগুলো ঠিক আছে
১৬.১৪ Daily Sales স্ক্রিনে প্রোডাক্ট সার্চ — দুই-ধাপে ও ছবিসহ হওয়া দরকার
বর্তমানে daily_sales_screen.dart-এ একটাই ফ্ল্যাট Autocomplete ফিল্ড — নাম ও ক্যাটাগরি দুটোই একসাথে এক সার্চে ম্যাচ করে (p.name.contains(query) || p.category.contains(query)), ফলাফল লিস্টে শুধু নাম দেখায়, কোনো ছবি নেই
ব্যবহারকারীর অনুরোধ: দুই ধাপের ফ্লো — ১. আগে ক্যাটাগরি বেছে নেওয়া ২. তারপর সেই ক্যাটাগরির মধ্যেই প্রোডাক্টের নির্দিষ্ট নাম দিয়ে সার্চ করা
প্রতিটা প্রোডাক্ট অপশনের পাশে ছোট সাইজের থাম্বনেইল ছবি দেখানো (জায়গা বাঁচাতে ছোট রাখা, তবে ছবি দেখেই প্রোডাক্ট চেনা যাবে) — এটা §১৬.২/১৬.১৩-এ চিহ্নিত প্রোডাক্ট-ছবি ফিচারের উপর নির্ভরশীল, সেটা যোগ হলে তবেই এখানে দেখানো সম্ভব
১৬.১৫ স্টকে প্রতিটা ক্যাটাগরির মোট মূল্য একসাথে (তালিকা আকারে) দেখা যায় না — নতুন ফিচার-অনুরোধ, রিগ্রেশন না
⚠️ সংশোধন: পুরনো অ্যাপের কোড আবার যাচাই করে দেখা গেছে যে সেখানেও "All" বাছলে শুধু একটাই মোট সংখ্যা (সব ক্যাটাগরি মিলিয়ে) দেখাতো, প্রতিটা ক্যাটাগরি আলাদা সারিতে দেখাতো না — categoryTotals ম্যাপ ভেতরে বানানো হলেও শুধু .values.fold(...) দিয়ে যোগ করে একটা সংখ্যায় নামিয়ে আনা হতো
নতুন অ্যাপও ঠিক একই আচরণ করে — "All Categories" বাছলে একটাই মোট, নির্দিষ্ট ক্যাটাগরি বাছলে তার টোটাল — এই অংশে দুই অ্যাপের মধ্যে কোনো পার্থক্য নেই, তাই এটা রিগ্রেশন না
প্রতিটা ক্যাটাগরির টোটাল একসাথে, তালিকা আকারে (যেমন: বই ৫০০০৳, আতর ৩০০০৳...) দেখানো — এটা কোনো অ্যাপেই কখনো ছিল না, এটা একটা নতুন ফিচার-অনুরোধ
ব্যবহারকারীর অনুরোধ: স্টক স্ক্রিনে প্রতিটা ক্যাটাগরির মোট টাকার পরিমাণ একসাথে (ব্রেকডাউন তালিকা আকারে, ফিল্টার না বদলেই) দেখা যাবে — এটা নতুন সংযোজন হিসেবে বানাতে হবে
(কনফার্মেশন — এই দুটো ইতিমধ্যে ঠিকভাবে কাজ করে, ফিক্স লাগবে না)
সেল করলে স্টক থেকে সংখ্যা সঠিকভাবে কমে যায় (SaveSaleUseCase → db.productDao.adjustQty)
Daily Sales-এ প্রোডাক্ট বাছলে ডিফল্ট sell price ও qty (=১) অটো বসে, ম্যানুয়ালি বদলানো যায় — এটা ঠিক আছে
১৬.১৬ স্টক কমে গেলে অ্যালার্ট — নতুন ফিচার-অনুরোধ (দুই অ্যাপেই ছিল না)
reminder_engine.dart-এ ৬ ধরনের রিমাইন্ডার আছে (Due balance, Investor capital return, Investor profit payout, Suspicious customer, Overdue rent, Order deadline) — কিন্তু লো-স্টক/স্টক-শেষ কোনো রিমাইন্ডার টাইপ নেই
পুরনো অ্যাপে শুধু ভিজ্যুয়াল হাইলাইট ছিল (out-of-stock লাল, low-stock হলুদ প্রোডাক্ট কার্ডে) — কোনো একটিভ অ্যালার্ট/নোটিফিকেশন ছিল না, নতুনেও তাই
ব্যবহারকারীর অনুরোধ: কোনো প্রোডাক্টের স্টক একটা নির্দিষ্ট মাত্রার নিচে নেমে গেলে সক্রিয়ভাবে অ্যালার্ট/রিমাইন্ডার দেওয়া — এটা Reminder Engine-এ একটা নতুন ৭ম টাইপ (LowStockReminder) হিসেবে যোগ করা যেতে পারে, বাকি রিমাইন্ডারগুলোর প্যাটার্ন অনুসরণ করে
১৬.১৭ স্টক লিস্টে আউট-অফ-স্টক/লো-স্টক রঙিন হাইলাইট — নতুনে সম্পূর্ণ অনুপস্থিত, পুরনোয় ছিল
stock_screen.dart-এর _ProductRow widget-এ কোনো রঙ-ভিত্তিক কন্ডিশনাল স্টাইলিং নেই — শুধু প্লেইন টেক্সটে নাম/দাম/সংখ্যা দেখায়
পুরনো অ্যাপে আউট-অফ-স্টক প্রোডাক্ট কার্ড লাল, লো-স্টক (threshold-এর নিচে) কার্ড হলুদ ব্যাকগ্রাউন্ডে হাইলাইট হতো — এটা নতুনে পুরোপুরি বাদ পড়ে গেছে
ব্যবহারকারীর অনুরোধ: এই ভিজ্যুয়াল হাইলাইট (লাল/হলুদ) নতুন অ্যাপেও ফিরিয়ে আনতে হবে — এটা §১৬.১৬-এর সক্রিয় অ্যালার্ট/রিমাইন্ডার ফিচারের পাশাপাশি, তার বদলে না — দুটোই দরকার
১৬.১৮ বই/রেন্ট সংক্রান্ত ফিল্ড স্টক এন্ট্রি থেকে সরিয়ে রেন্ট-ইস্যু সময়ে আনা — §১৬.১৩-এর পরিমার্জন

এটা আগের §১৬.১৩-এ বলা "ক্যাটাগরি বই হলে rent ফিল্ড অটো দেখানো"-এর চেয়ে আরও স্পষ্ট/আলাদা সিদ্ধান্ত — এটাই চূড়ান্ত ধরে নিতে হবে:

প্রোডাক্ট/স্টক এন্ট্রি ফর্ম থেকে সম্পূর্ণ বাদ: "Rent a book?" টগল ও page count ফিল্ড — এগুলো প্রোডাক্ট তৈরির সময় জিজ্ঞাসা করা যাবে না
রেন্ট-ইস্যু ফর্মে (Rent স্ক্রিনে, "Issue Rent" করার সময়) নতুন করে যোগ করতে হবে:
পেজ সংখ্যা (page count) — এখন পর্যন্ত এটা Product entity-তে সেট হতো তৈরির সময়, এখন থেকে রেন্ট দেওয়ার সময় লাইভ ইনপুট নিতে হবে
কাস্টমারের নাম — বর্তমানে rent_screen.dart-এ এটা আগে থেকে থাকা কাস্টমারদের ড্রপডাউন মাত্র (controller.customers), নতুন কাস্টমারের নাম টাইপ করে সরাসরি যোগ করার কোনো উপায় নেই — এটা ইনপুট-ফিল্ড/ইনলাইন-অ্যাড হিসেবে থাকা দরকার
মোবাইল নম্বর — বর্তমানে রেন্ট ফর্মে নেই
কতদিনের জন্য (days) — এটা ইতিমধ্যেই আছে (_daysController), ঠিক আছে
কাস্টমার সেকশনের সাথে সংযোগ: রেন্ট-ইস্যুর সময় দেওয়া নাম/মোবাইল/রেন্ট তথ্য যেন Customer প্রোফাইলেও প্রতিফলিত হয় (নতুন কাস্টমার হলে তৈরি হয়ে যাবে, পুরনো হলে লিংক হবে) — যাতে ভবিষ্যতে রিমাইন্ডার ও কাস্টমার-হিস্ট্রি/হিসাবে এই ডেটা কাজে লাগে

(এটা লক্ষ্যণীয় যে বর্তমান কোডে RentTransaction ইতিমধ্যেই customerId দিয়ে Customer-এর সাথে লিংকড, এবং Reminder Engine-এর OverdueRentReminder সেই লিংক ব্যবহার করে — তাই কাঠামোগত ভিত্তিটা আছে, শুধু ফর্মের ইনপুট-ফ্লো বদলাতে হবে।)

১৬.১৯ ইনভেস্টর যোগ ফর্মে ক্যালেন্ডার পপ-আপ ও লেনদেন-স্ট্যাটাস ভিউ
capitalReturnTermDays বর্তমানে শুধু একটা সংখ্যা-ইনপুট (কত দিন) হিসেবে আছে
অনুরোধ: এটার সাথে একটা ক্যালেন্ডার পপ-আপ থাকা উচিত, যাতে সরাসরি একটা তারিখ বেছে সহজে ফেরতের দিন ঠিক করা যায়
অনুরোধ: ইনভেস্টর প্রোফাইলে (বা তার ডিটেইলস ভিউতে) সেই ইনভেস্টর ও দোকানের মধ্যে বর্তমান সব লেনদেনের একটা স্ট্যাটাস-সারাংশ দেখানো উচিত (কী বাকি, কী দেওয়া হয়েছে, কবে ফেরত দেওয়ার কথা ইত্যাদি একনজরে)
১৬.২০ Overview পেজে দৈনিক ও সর্বমোট "To Give Away" দেখানো
বর্তমানে Overview-এ এই ধরনের কোনো ফিগারই নেই (§১৬.৮-এ আগেই বলা হয়েছে "To Give Away" কার্ডটাই অনুপস্থিত)
অনুরোধ স্পষ্ট করে: শুধু কার্ড ফিরিয়ে আনাই না — প্রতিদিন কত ইনভেস্টরদের দিতে হবে এবং সর্বমোট (all-time) কত বাকি আছে দেওয়ার জন্য — দুটো আলাদা সংখ্যা একসাথে দেখানো
১৬.২১ কাস্টমার সিস্টেম — পুরনো অ্যাপের পুরো কাঠামো ফিরিয়ে এনে নতুন ফিচারের সাথে একীভূত করা
আগে §৮-এ বলা হয়েছিল নতুন অ্যাপে কাস্টমার টাইপ পুরোপুরি ফিক্সড ভিউ, ফ্রি-ফর্ম কাস্টম সেকশন নেই
ব্যবহারকারীর স্পষ্ট সিদ্ধান্ত: পুরনো অ্যাপের পুরো কাস্টমার সিস্টেম (কাস্টম সেকশন/টাইপ যোগ করা, প্রতি কাস্টমারের পার্চেজ/অর্ডার/রেন্টাল/বাকি সাব-লিস্ট ইত্যাদি) ফিরিয়ে আনতে হবে, এবং সেটাকে নতুন অ্যাপের নতুন ফিচারগুলোর (suspicionFlag, isBlocked, Due entity, ইত্যাদি) সাথে একীভূত (merge) করতে হবে — একটা প্রতিস্থাপন না করে দুটোর সেরা অংশ মিলিয়ে
স্বয়ংক্রিয় কাস্টমার-সংযোগ: অন্য যেকোনো পেজে (Daily Sales, Rent-issue, Purchase Entry, Dues ইত্যাদি) কোথাও একটা নতুন নাম টাইপ/এন্টার করা হলে, Customers সেকশন সেই নামটা নিজে থেকে ধরে নিয়ে নিজের একটা এন্ট্রি বানিয়ে ফেলবে, এবং তার সাথে সংশ্লিষ্ট লেনদেনের একটা সারসংক্ষেপ ("gross transaction") যুক্ত থাকবে — অর্থাৎ কোথাও থেকে একটা নাম দিলেই সেটা Customers-এ প্রতিফলিত হবে, আলাদা করে কাস্টমার তৈরি করতে হবে না
১৬.২২ Purchase Entry — বটম ন্যাভে আনা ও ফর্মের সম্পূর্ণ পুনর্গঠন

নেভিগেশন: কনফার্মড — বর্তমানে Purchase Entry শুধু ড্রয়ারে আছে (app_drawer.dart → 'purchaseEntry'.tr), বটম ন্যাভে নেই। অনুরোধ: এটা বটম ন্যাভেই থাকা উচিত (সহজে দ্রুত অ্যাক্সেসের জন্য)।

ফর্মের ফিচার-বাই-ফিচার অবস্থা:

ফিচার	বর্তমান অবস্থা
ট্রিপের তারিখ	✅ আছে (tripDate)
কার কাছ থেকে (নিজে/ইনভেস্টর) ও পরিমাণ	⚠️ আংশিক — প্রতিটা আইটেমের নিজস্ব fundSource আছে (ঠিক আছে), কিন্তু ট্রিপ-লেভেলে "মোট কত টাকা নিয়ে বের হয়েছি" এই একটা স্পষ্ট ইনপুট ফিল্ড নেই — শুধু হিসাব থেকে অনুমান করা হয়
নতুন ইনভেস্টর হলে সরাসরি এখান থেকে যোগ করে ফিরে আসা	❌ নেই — Purchase Entry স্ক্রিনে ইনভেস্টর অ্যাড করার কোনো ইনলাইন পথ নেই, আগে থেকে Investor স্ক্রিনে গিয়ে বানিয়ে রাখতে হবে
একাধিক ক্যাটাগরি/দোকান থেকে বাল্ক কেনা	✅ আছে — প্রতিটা item-এর নিজস্ব shopName ও productId, একই ট্রিপে একাধিক আইটেম যোগ করা যায়
ক্যাশ মেমোর ছবি (ঐচ্ছিক)	❌ নেই — Purchase entity-তে কোনো ছবি/মেমো ফিল্ড নেই (§১৬.২-এর সম্পূর্ণ-অনুপস্থিত ছবি-ফিচারের অংশ)
Other cost, Transport cost, Returned cash	✅ সবগুলোই আছে
যোগফল না মিললে নোটিশ	⚠️ আংশিক — reconcilePurchaseTrip() ফাংশন সঠিক হিসাব করে (item cost + transport + other − returned), এবং reconciles(actualCashTakenOut) একটা true/false চেক দেয়ও — কিন্তু ফর্মে "actualCashTakenOut" ইনপুট করার আলাদা ফিল্ড নেই এবং ইউজারকে দেখানোর মতো কোনো ভিজিবল "নোটিশ/wজ্ঞাপন" UI-তে বসানো নেই — ব্যাকএন্ড লজিক তৈরি কিন্তু ফ্রন্টএন্ডে সংযুক্ত হয়নি
এন্ট্রি এডিট করা যাবে	❌ নেই — স্ক্রিনের নিজের কোড কমেন্টেই লেখা: "does nothing, since this v2 screen has no 'edit an existing trip'" — শুধু ডিলিট করা যায়, এডিট করা যায় না
পার্চেজ ডেটা সেভ থাকা	✅ ঠিকভাবে কাজ করে
ক্যাটাগরি-ভিত্তিক বাল্ক কেনা স্টকের individual এন্ট্রির সাথে মিলে যাওয়া	✅ ইতিমধ্যেই সঠিকভাবে কাজ করে — SavePurchaseTripUseCase-এ প্রতিটা item সেভ হওয়ার সাথে সাথে db.productDao.adjustQty(item.productId, item.qty, now) কল হয়ে সংশ্লিষ্ট প্রোডাক্টের স্টকে যোগ হয়ে যায় — এটা ঠিক আছে, ফিক্স লাগবে না

সংক্ষেপে যা যোগ/ফিক্স করতে হবে: বটম ন্যাভে আনা, ট্রিপ-লেভেল cash-taken ইনপুট + রিকনসিলিয়েশন নোটিশ UI-তে সংযুক্ত করা, ইনলাইন নতুন-ইনভেস্টর-যোগ ফ্লো, ক্যাশ মেমো ছবি (ছবি ফিচার তৈরি হওয়ার পর), এবং ট্রিপ এডিট করার সুবিধা।

১৬.১৯ Investor ফর্মে capitalReturnTermDays — ক্যালেন্ডার পপ-আপ ও লেনদেনের অবস্থা দেখানো
বর্তমানে investor_form_sheet.dart-এ capitalReturnTermDays একটা প্লেইন TextFormField — সরাসরি দিন-সংখ্যা টাইপ করতে হয় (যেমন "৯০")
একই ফাইলে showDatePicker ব্যবহার হচ্ছে ঠিকই, কিন্তু সেটা শুধু Legacy Settlement Date-এর জন্য, capitalReturnTermDays-এর সাথে সংযুক্ত না
ব্যবহারকারীর অনুরোধ: ১. capitalReturnTermDays-কে সংখ্যা-টাইপের বদলে ক্যালেন্ডার পপ-আপ দিয়ে সহজে একটা নির্দিষ্ট তারিখ বেছে নেওয়ার ব্যবস্থা করা — তারিখ বাছলে আজকের তারিখ থেকে হিসাব করে দিন-সংখ্যা অটো বসে যাবে ২. এই ফর্ম/ফ্লোতে সেই ইনভেস্টরের সাথে দোকানের বর্তমান সব লেনদেনের অবস্থা (মোট বিনিয়োগ, ফেরত-বাকি মূলধন, পাওনা লাভ ইত্যাদি) একসাথে দেখানো — যাতে নতুন টার্ম সেট করার সময়ই প্রেক্ষাপট বোঝা যায়
১৬.২০ কাস্টমার প্রোফাইলে ক্রয়/বাকি/ভাড়ার হিস্ট্রি দেখানো — ডিজাইনে ছিল, বাস্তবায়ন হয়নি

এটা আপনার একদম শুরুর মেসেজে বলা "কাস্টমার সেকশনে তাদের সাথে লেনদেন ও বাকি থাকবে" — এই চাহিদার সাথে সরাসরি সম্পর্কিত, এবং পুরনো অ্যাপে (buyer কার্ডে Purchases লিস্ট আকারে) এটা ছিল।

Customer এনটিটির কোড-কমেন্টেই লেখা: buyer/order-giver/renter/due-taker আলাদা টাইপ না, এগুলো Sale/Order/Rent/Due রেকর্ডের সাথে জয়েন করা "filtered view" হওয়ার কথা — অর্থাৎ ডিজাইনের ইচ্ছা ছিল কাস্টমার প্রোফাইলে গেলে তার সব লেনদেনের ইতিহাস একসাথে দেখানো
কিন্তু বাস্তবে customers_screen.dart-এ কাস্টমারের নামে ট্যাপ করলে শুধু এডিট ফর্ম (নাম/ঠিকানা/মোবাইল/ফ্ল্যাগ) খোলে
কোনো কাস্টমার-ডিটেইল/প্রোফাইল স্ক্রিন নেই যেখানে তার Sale (কী কিনেছে), Due (বাকি), Rent (ভাড়ার ইতিহাস), Order — এসবের জোড়া-লাগানো তালিকা দেখা যায়
মানে এই ফিচারের স্থাপত্যিক ভিত্তি (architecture) তৈরি আছে (কমেন্টে বলা আছে), কিন্তু বাস্তব UI বানানোই হয়নি — এটা নিছক অসম্পূর্ণ কাজ, ডিজাইন-সিদ্ধান্ত না
ব্যবহারকারীর অনুরোধ: কাস্টমার প্রোফাইল/ডিটেইল ভিউ বানাতে হবে যেখানে সেই কাস্টমারের সব কেনাকাটা, বাকি, ভাড়ার ইতিহাস একসাথে দেখা যাবে — পুরনো অ্যাপের মতো, কিন্তু নতুনের ডেটা-মডেল অনুযায়ী (আলাদা টাইপ না, একটাই কাস্টমারের নিচে সব লেনদেন)

so in the add expence section in the drawer There will be repeat option for every month and a button for repay confermation like the old app and the rest is ok ithink 

you suggest how can it be good 

if i repay loan of an investor than will it make a data 

or how it effect my balance and pricing

Analyzed pricing mechanism and designed repeat repay feature

Good news — I checked the code, and this maps very well onto what already exists. Here's the picture.

What's already there vs. what you're asking for

The new app's Expense entity is currently very bare — just category, amount, date, description, payment method. No isPaid, no recurringType, no dueDay, and the use-case doc comment explicitly says expenses can't be edited, only deleted (because editing would leave the paired cash-ledger entry wrong).

Your old app had exactly what you're describing:

recurringType (none / monthly / daily / custom) on each expense
isPaid boolean + a "mark paid" toggle
When you tap "mark paid" on a recurring expense, it auto-creates the next occurrence (same category/amount/vendor, date pushed forward by a month/day), inserted right after it, unpaid
How I'd rebuild it in the new app
Add recurringType and dueDay to the Expense entity/table (same enum idea as before: none/daily/monthly/custom).
Add a "Repay" (confirm paid) button on each expense row — instead of editing the expense in place (which the architecture deliberately avoids), this button:
Records the current expense as paid (a real create() call — same as any other expense, writes the expenses row + a negative cash_ledger_entries row, so it reduces Total Cash correctly)
If recurringType != none, automatically creates the next occurrence as a new unpaid/upcoming expense row dated a month (or day) later
Since the new architecture treats expenses as append-only (no edit), "unpaid" recurring expenses that haven't been confirmed yet should probably live as a lightweight "upcoming/scheduled expense" reminder (tie into the existing reminder_engine.dart, which already has 6 reminder types — this becomes a natural 7th/8th: "Recurring bill due"), and only become a real Expense row once you hit Repay/Confirm. That keeps the ledger clean (only actual cash-outs are real Expense rows) while still giving you the "due this month" list and the one-tap confirm button like before.

That's the design I'd suggest — reuse the reminder engine for "upcoming," and only write a real Expense (with its ledger entry) at confirmation time.

Your investor repayment question

Yes — repaying an investor does create real data, and it's treated as seriously as any other cash movement:

It writes an InvestorRepayment row and a matching negative cash_ledger_entries row in the same transaction — so it hits Total Cash immediately, exactly like an expense or a purchase does.
There are two repayment types, and they behave differently:
capitalReturn — this reduces the investor's remainingBalance (how much of their original investment the shop still owes them). This is the actual loan repayment.
profitShare — this is paying out their profit cut. It does not reduce remainingBalance — paying someone their profit doesn't shrink the capital you owe them.

Does it affect pricing? No — and this is worth knowing. The pricing engine's markup suggestion only looks at the investor's ongoing profitSharePercent (their agreed cut of gross profit), not their outstanding balance. And for a cashLoan-type investor specifically, the profit share is always 0% by design (a straight loan, no profit cut) — so repaying a loan investor doesn't change product pricing at all, before or after repayment. Pricing only shifts if the contract type or percentage itself changes.

so in the add expence section in the drawer There will be repeat option for every month and a button for repay confermation like the old app and the rest is ok ithink 

you suggest how can it be good 

if i repay loan of an investor than will it make a data 

or how it effect my balance and pricing

Looks like this came through twice — I answered this one just above. Quick recap of the key points:

Expense repeat + repay button — I'd rebuild it as: add recurringType back to the Expense model, and make "Repay/Confirm" the button that actually writes the real expense (hits Total Cash), while an unconfirmed recurring bill sits as an upcoming reminder (via the existing reminder engine) until you confirm it — so the ledger only ever contains real, confirmed cash-outs.

Investor loan repayment — yes, it creates real data: an InvestorRepayment row + a matching cash-ledger entry, so it reduces Total Cash immediately. If it's marked capitalReturn, it reduces what the shop still owes that investor. It does not touch pricing — the pricing engine only cares about an investor's ongoing profit-share %, and loan investors have 0% share by design, so repaying the loan doesn't move product prices at all.

Want me to add this Expense repeat/repay item as a new numbered entry in the task-list file I made earlier, so it's in the same doc you hand to the agent? And go ahead and send the rest of your list whenever ready — I'll fold each one in the same way.

did i miss any thing  in both of the  app that you keep my ones and if any good in any of them that are good merge to make my final agent file

Audited both apps, identified gaps, and consolidated actionable items

Good catch to double check — I found one more real gap while verifying: the Due entity has no link to a product's investor/fund source at all, even though the spec calls for notifying the investor when a due is on their product. That wasn't in my first list. Let me build the complete, final merged spec now.

Created a file, ran a command, read a file

This is the merged, final version — it replaces the earlier partial list. I re-checked both codebases against everything discussed so far and found two things I'd missed the first time:

Daily Sales two-step search (pick category, then search within it) — I'd only mentioned the thumbnail part before, not the category-first flow itself.
Due entity has no link to a product's investor — confirmed by reading due.dart. The spec calls for notifying the investor when a due is on their product, but there's no structural connection to make that possible yet. Real gap, not previously flagged.