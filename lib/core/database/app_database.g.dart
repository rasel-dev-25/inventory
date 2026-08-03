// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _investorMeta = const VerificationMeta(
    'investor',
  );
  @override
  late final GeneratedColumn<String> investor = GeneratedColumn<String>(
    'investor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Own Shop'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyQtyMeta = const VerificationMeta('buyQty');
  @override
  late final GeneratedColumn<double> buyQty = GeneratedColumn<double>(
    'buy_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _buyUnitMeta = const VerificationMeta(
    'buyUnit',
  );
  @override
  late final GeneratedColumn<String> buyUnit = GeneratedColumn<String>(
    'buy_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _buyPriceMeta = const VerificationMeta(
    'buyPrice',
  );
  @override
  late final GeneratedColumn<double> buyPrice = GeneratedColumn<double>(
    'buy_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellUnitMeta = const VerificationMeta(
    'sellUnit',
  );
  @override
  late final GeneratedColumn<String> sellUnit = GeneratedColumn<String>(
    'sell_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<double> sellPrice = GeneratedColumn<double>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _buyConversionFactorMeta =
      const VerificationMeta('buyConversionFactor');
  @override
  late final GeneratedColumn<double> buyConversionFactor =
      GeneratedColumn<double>(
        'buy_conversion_factor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      );
  static const VerificationMeta _sellConversionFactorMeta =
      const VerificationMeta('sellConversionFactor');
  @override
  late final GeneratedColumn<double> sellConversionFactor =
      GeneratedColumn<double>(
        'sell_conversion_factor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    investor,
    name,
    buyQty,
    buyUnit,
    buyPrice,
    sellUnit,
    sellPrice,
    qty,
    buyConversionFactor,
    sellConversionFactor,
    date,
    imagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('investor')) {
      context.handle(
        _investorMeta,
        investor.isAcceptableOrUnknown(data['investor']!, _investorMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('buy_qty')) {
      context.handle(
        _buyQtyMeta,
        buyQty.isAcceptableOrUnknown(data['buy_qty']!, _buyQtyMeta),
      );
    }
    if (data.containsKey('buy_unit')) {
      context.handle(
        _buyUnitMeta,
        buyUnit.isAcceptableOrUnknown(data['buy_unit']!, _buyUnitMeta),
      );
    }
    if (data.containsKey('buy_price')) {
      context.handle(
        _buyPriceMeta,
        buyPrice.isAcceptableOrUnknown(data['buy_price']!, _buyPriceMeta),
      );
    }
    if (data.containsKey('sell_unit')) {
      context.handle(
        _sellUnitMeta,
        sellUnit.isAcceptableOrUnknown(data['sell_unit']!, _sellUnitMeta),
      );
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('buy_conversion_factor')) {
      context.handle(
        _buyConversionFactorMeta,
        buyConversionFactor.isAcceptableOrUnknown(
          data['buy_conversion_factor']!,
          _buyConversionFactorMeta,
        ),
      );
    }
    if (data.containsKey('sell_conversion_factor')) {
      context.handle(
        _sellConversionFactorMeta,
        sellConversionFactor.isAcceptableOrUnknown(
          data['sell_conversion_factor']!,
          _sellConversionFactorMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      investor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investor'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      buyQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_qty'],
      )!,
      buyUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buy_unit'],
      )!,
      buyPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_price'],
      )!,
      sellUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sell_unit'],
      )!,
      sellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_price'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      )!,
      buyConversionFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}buy_conversion_factor'],
      )!,
      sellConversionFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sell_conversion_factor'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String category;
  final String investor;
  final String name;
  final double buyQty;
  final String buyUnit;
  final double buyPrice;
  final String sellUnit;
  final double sellPrice;
  final double qty;
  final double buyConversionFactor;
  final double sellConversionFactor;
  final String date;
  final String imagePath;
  const Product({
    required this.id,
    required this.category,
    required this.investor,
    required this.name,
    required this.buyQty,
    required this.buyUnit,
    required this.buyPrice,
    required this.sellUnit,
    required this.sellPrice,
    required this.qty,
    required this.buyConversionFactor,
    required this.sellConversionFactor,
    required this.date,
    required this.imagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['investor'] = Variable<String>(investor);
    map['name'] = Variable<String>(name);
    map['buy_qty'] = Variable<double>(buyQty);
    map['buy_unit'] = Variable<String>(buyUnit);
    map['buy_price'] = Variable<double>(buyPrice);
    map['sell_unit'] = Variable<String>(sellUnit);
    map['sell_price'] = Variable<double>(sellPrice);
    map['qty'] = Variable<double>(qty);
    map['buy_conversion_factor'] = Variable<double>(buyConversionFactor);
    map['sell_conversion_factor'] = Variable<double>(sellConversionFactor);
    map['date'] = Variable<String>(date);
    map['image_path'] = Variable<String>(imagePath);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      category: Value(category),
      investor: Value(investor),
      name: Value(name),
      buyQty: Value(buyQty),
      buyUnit: Value(buyUnit),
      buyPrice: Value(buyPrice),
      sellUnit: Value(sellUnit),
      sellPrice: Value(sellPrice),
      qty: Value(qty),
      buyConversionFactor: Value(buyConversionFactor),
      sellConversionFactor: Value(sellConversionFactor),
      date: Value(date),
      imagePath: Value(imagePath),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      investor: serializer.fromJson<String>(json['investor']),
      name: serializer.fromJson<String>(json['name']),
      buyQty: serializer.fromJson<double>(json['buyQty']),
      buyUnit: serializer.fromJson<String>(json['buyUnit']),
      buyPrice: serializer.fromJson<double>(json['buyPrice']),
      sellUnit: serializer.fromJson<String>(json['sellUnit']),
      sellPrice: serializer.fromJson<double>(json['sellPrice']),
      qty: serializer.fromJson<double>(json['qty']),
      buyConversionFactor: serializer.fromJson<double>(
        json['buyConversionFactor'],
      ),
      sellConversionFactor: serializer.fromJson<double>(
        json['sellConversionFactor'],
      ),
      date: serializer.fromJson<String>(json['date']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'investor': serializer.toJson<String>(investor),
      'name': serializer.toJson<String>(name),
      'buyQty': serializer.toJson<double>(buyQty),
      'buyUnit': serializer.toJson<String>(buyUnit),
      'buyPrice': serializer.toJson<double>(buyPrice),
      'sellUnit': serializer.toJson<String>(sellUnit),
      'sellPrice': serializer.toJson<double>(sellPrice),
      'qty': serializer.toJson<double>(qty),
      'buyConversionFactor': serializer.toJson<double>(buyConversionFactor),
      'sellConversionFactor': serializer.toJson<double>(sellConversionFactor),
      'date': serializer.toJson<String>(date),
      'imagePath': serializer.toJson<String>(imagePath),
    };
  }

  Product copyWith({
    String? id,
    String? category,
    String? investor,
    String? name,
    double? buyQty,
    String? buyUnit,
    double? buyPrice,
    String? sellUnit,
    double? sellPrice,
    double? qty,
    double? buyConversionFactor,
    double? sellConversionFactor,
    String? date,
    String? imagePath,
  }) => Product(
    id: id ?? this.id,
    category: category ?? this.category,
    investor: investor ?? this.investor,
    name: name ?? this.name,
    buyQty: buyQty ?? this.buyQty,
    buyUnit: buyUnit ?? this.buyUnit,
    buyPrice: buyPrice ?? this.buyPrice,
    sellUnit: sellUnit ?? this.sellUnit,
    sellPrice: sellPrice ?? this.sellPrice,
    qty: qty ?? this.qty,
    buyConversionFactor: buyConversionFactor ?? this.buyConversionFactor,
    sellConversionFactor: sellConversionFactor ?? this.sellConversionFactor,
    date: date ?? this.date,
    imagePath: imagePath ?? this.imagePath,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      investor: data.investor.present ? data.investor.value : this.investor,
      name: data.name.present ? data.name.value : this.name,
      buyQty: data.buyQty.present ? data.buyQty.value : this.buyQty,
      buyUnit: data.buyUnit.present ? data.buyUnit.value : this.buyUnit,
      buyPrice: data.buyPrice.present ? data.buyPrice.value : this.buyPrice,
      sellUnit: data.sellUnit.present ? data.sellUnit.value : this.sellUnit,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      qty: data.qty.present ? data.qty.value : this.qty,
      buyConversionFactor: data.buyConversionFactor.present
          ? data.buyConversionFactor.value
          : this.buyConversionFactor,
      sellConversionFactor: data.sellConversionFactor.present
          ? data.sellConversionFactor.value
          : this.sellConversionFactor,
      date: data.date.present ? data.date.value : this.date,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('investor: $investor, ')
          ..write('name: $name, ')
          ..write('buyQty: $buyQty, ')
          ..write('buyUnit: $buyUnit, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellUnit: $sellUnit, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('qty: $qty, ')
          ..write('buyConversionFactor: $buyConversionFactor, ')
          ..write('sellConversionFactor: $sellConversionFactor, ')
          ..write('date: $date, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    investor,
    name,
    buyQty,
    buyUnit,
    buyPrice,
    sellUnit,
    sellPrice,
    qty,
    buyConversionFactor,
    sellConversionFactor,
    date,
    imagePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.category == this.category &&
          other.investor == this.investor &&
          other.name == this.name &&
          other.buyQty == this.buyQty &&
          other.buyUnit == this.buyUnit &&
          other.buyPrice == this.buyPrice &&
          other.sellUnit == this.sellUnit &&
          other.sellPrice == this.sellPrice &&
          other.qty == this.qty &&
          other.buyConversionFactor == this.buyConversionFactor &&
          other.sellConversionFactor == this.sellConversionFactor &&
          other.date == this.date &&
          other.imagePath == this.imagePath);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> investor;
  final Value<String> name;
  final Value<double> buyQty;
  final Value<String> buyUnit;
  final Value<double> buyPrice;
  final Value<String> sellUnit;
  final Value<double> sellPrice;
  final Value<double> qty;
  final Value<double> buyConversionFactor;
  final Value<double> sellConversionFactor;
  final Value<String> date;
  final Value<String> imagePath;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.investor = const Value.absent(),
    this.name = const Value.absent(),
    this.buyQty = const Value.absent(),
    this.buyUnit = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.sellUnit = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.qty = const Value.absent(),
    this.buyConversionFactor = const Value.absent(),
    this.sellConversionFactor = const Value.absent(),
    this.date = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    this.category = const Value.absent(),
    this.investor = const Value.absent(),
    required String name,
    this.buyQty = const Value.absent(),
    this.buyUnit = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.sellUnit = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.qty = const Value.absent(),
    this.buyConversionFactor = const Value.absent(),
    this.sellConversionFactor = const Value.absent(),
    required String date,
    this.imagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       date = Value(date);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? investor,
    Expression<String>? name,
    Expression<double>? buyQty,
    Expression<String>? buyUnit,
    Expression<double>? buyPrice,
    Expression<String>? sellUnit,
    Expression<double>? sellPrice,
    Expression<double>? qty,
    Expression<double>? buyConversionFactor,
    Expression<double>? sellConversionFactor,
    Expression<String>? date,
    Expression<String>? imagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (investor != null) 'investor': investor,
      if (name != null) 'name': name,
      if (buyQty != null) 'buy_qty': buyQty,
      if (buyUnit != null) 'buy_unit': buyUnit,
      if (buyPrice != null) 'buy_price': buyPrice,
      if (sellUnit != null) 'sell_unit': sellUnit,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (qty != null) 'qty': qty,
      if (buyConversionFactor != null)
        'buy_conversion_factor': buyConversionFactor,
      if (sellConversionFactor != null)
        'sell_conversion_factor': sellConversionFactor,
      if (date != null) 'date': date,
      if (imagePath != null) 'image_path': imagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? investor,
    Value<String>? name,
    Value<double>? buyQty,
    Value<String>? buyUnit,
    Value<double>? buyPrice,
    Value<String>? sellUnit,
    Value<double>? sellPrice,
    Value<double>? qty,
    Value<double>? buyConversionFactor,
    Value<double>? sellConversionFactor,
    Value<String>? date,
    Value<String>? imagePath,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      investor: investor ?? this.investor,
      name: name ?? this.name,
      buyQty: buyQty ?? this.buyQty,
      buyUnit: buyUnit ?? this.buyUnit,
      buyPrice: buyPrice ?? this.buyPrice,
      sellUnit: sellUnit ?? this.sellUnit,
      sellPrice: sellPrice ?? this.sellPrice,
      qty: qty ?? this.qty,
      buyConversionFactor: buyConversionFactor ?? this.buyConversionFactor,
      sellConversionFactor: sellConversionFactor ?? this.sellConversionFactor,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (investor.present) {
      map['investor'] = Variable<String>(investor.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (buyQty.present) {
      map['buy_qty'] = Variable<double>(buyQty.value);
    }
    if (buyUnit.present) {
      map['buy_unit'] = Variable<String>(buyUnit.value);
    }
    if (buyPrice.present) {
      map['buy_price'] = Variable<double>(buyPrice.value);
    }
    if (sellUnit.present) {
      map['sell_unit'] = Variable<String>(sellUnit.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<double>(sellPrice.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (buyConversionFactor.present) {
      map['buy_conversion_factor'] = Variable<double>(
        buyConversionFactor.value,
      );
    }
    if (sellConversionFactor.present) {
      map['sell_conversion_factor'] = Variable<double>(
        sellConversionFactor.value,
      );
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('investor: $investor, ')
          ..write('name: $name, ')
          ..write('buyQty: $buyQty, ')
          ..write('buyUnit: $buyUnit, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellUnit: $sellUnit, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('qty: $qty, ')
          ..write('buyConversionFactor: $buyConversionFactor, ')
          ..write('sellConversionFactor: $sellConversionFactor, ')
          ..write('date: $date, ')
          ..write('imagePath: $imagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitMeta = const VerificationMeta('profit');
  @override
  late final GeneratedColumn<double> profit = GeneratedColumn<double>(
    'profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    productName,
    amount,
    profit,
    type,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('profit')) {
      context.handle(
        _profitMeta,
        profit.isAcceptableOrUnknown(data['profit']!, _profitMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      profit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;
  final String date;
  final String productName;
  final double amount;
  final double profit;
  final String type;
  const Sale({
    required this.id,
    required this.date,
    required this.productName,
    required this.amount,
    required this.profit,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['product_name'] = Variable<String>(productName);
    map['amount'] = Variable<double>(amount);
    map['profit'] = Variable<double>(profit);
    map['type'] = Variable<String>(type);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      date: Value(date),
      productName: Value(productName),
      amount: Value(amount),
      profit: Value(profit),
      type: Value(type),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      productName: serializer.fromJson<String>(json['productName']),
      amount: serializer.fromJson<double>(json['amount']),
      profit: serializer.fromJson<double>(json['profit']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'productName': serializer.toJson<String>(productName),
      'amount': serializer.toJson<double>(amount),
      'profit': serializer.toJson<double>(profit),
      'type': serializer.toJson<String>(type),
    };
  }

  Sale copyWith({
    String? id,
    String? date,
    String? productName,
    double? amount,
    double? profit,
    String? type,
  }) => Sale(
    id: id ?? this.id,
    date: date ?? this.date,
    productName: productName ?? this.productName,
    amount: amount ?? this.amount,
    profit: profit ?? this.profit,
    type: type ?? this.type,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      amount: data.amount.present ? data.amount.value : this.amount,
      profit: data.profit.present ? data.profit.value : this.profit,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('productName: $productName, ')
          ..write('amount: $amount, ')
          ..write('profit: $profit, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, productName, amount, profit, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.date == this.date &&
          other.productName == this.productName &&
          other.amount == this.amount &&
          other.profit == this.profit &&
          other.type == this.type);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> productName;
  final Value<double> amount;
  final Value<double> profit;
  final Value<String> type;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.productName = const Value.absent(),
    this.amount = const Value.absent(),
    this.profit = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    required String date,
    required String productName,
    required double amount,
    this.profit = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       productName = Value(productName),
       amount = Value(amount);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? productName,
    Expression<double>? amount,
    Expression<double>? profit,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (productName != null) 'product_name': productName,
      if (amount != null) 'amount': amount,
      if (profit != null) 'profit': profit,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? productName,
    Value<double>? amount,
    Value<double>? profit,
    Value<String>? type,
    Value<int>? rowid,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      amount: amount ?? this.amount,
      profit: profit ?? this.profit,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (profit.present) {
      map['profit'] = Variable<double>(profit.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('productName: $productName, ')
          ..write('amount: $amount, ')
          ..write('profit: $profit, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _whatsappMeta = const VerificationMeta(
    'whatsapp',
  );
  @override
  late final GeneratedColumn<String> whatsapp = GeneratedColumn<String>(
    'whatsapp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('buyer'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    whatsapp,
    imagePath,
    note,
    address,
    type,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('whatsapp')) {
      context.handle(
        _whatsappMeta,
        whatsapp.isAcceptableOrUnknown(data['whatsapp']!, _whatsappMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      whatsapp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String name;
  final String phone;
  final String whatsapp;
  final String imagePath;
  final String note;
  final String address;
  final String type;
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.imagePath,
    required this.note,
    required this.address,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['whatsapp'] = Variable<String>(whatsapp);
    map['image_path'] = Variable<String>(imagePath);
    map['note'] = Variable<String>(note);
    map['address'] = Variable<String>(address);
    map['type'] = Variable<String>(type);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      whatsapp: Value(whatsapp),
      imagePath: Value(imagePath),
      note: Value(note),
      address: Value(address),
      type: Value(type),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      whatsapp: serializer.fromJson<String>(json['whatsapp']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      note: serializer.fromJson<String>(json['note']),
      address: serializer.fromJson<String>(json['address']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'whatsapp': serializer.toJson<String>(whatsapp),
      'imagePath': serializer.toJson<String>(imagePath),
      'note': serializer.toJson<String>(note),
      'address': serializer.toJson<String>(address),
      'type': serializer.toJson<String>(type),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? whatsapp,
    String? imagePath,
    String? note,
    String? address,
    String? type,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    whatsapp: whatsapp ?? this.whatsapp,
    imagePath: imagePath ?? this.imagePath,
    note: note ?? this.note,
    address: address ?? this.address,
    type: type ?? this.type,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      whatsapp: data.whatsapp.present ? data.whatsapp.value : this.whatsapp,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      note: data.note.present ? data.note.value : this.note,
      address: data.address.present ? data.address.value : this.address,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note, ')
          ..write('address: $address, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, whatsapp, imagePath, note, address, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.whatsapp == this.whatsapp &&
          other.imagePath == this.imagePath &&
          other.note == this.note &&
          other.address == this.address &&
          other.type == this.type);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> whatsapp;
  final Value<String> imagePath;
  final Value<String> note;
  final Value<String> address;
  final Value<String> type;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
    this.address = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
    this.address = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? whatsapp,
    Expression<String>? imagePath,
    Expression<String>? note,
    Expression<String>? address,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (imagePath != null) 'image_path': imagePath,
      if (note != null) 'note': note,
      if (address != null) 'address': address,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? whatsapp,
    Value<String>? imagePath,
    Value<String>? note,
    Value<String>? address,
    Value<String>? type,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      address: address ?? this.address,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (whatsapp.present) {
      map['whatsapp'] = Variable<String>(whatsapp.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note, ')
          ..write('address: $address, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    date,
    amount,
    type,
    itemName,
    imagePath,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final int id;
  final String customerId;
  final String date;
  final double amount;
  final String type;
  final String itemName;
  final String imagePath;
  final String note;
  const LedgerEntry({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    required this.type,
    required this.itemName,
    required this.imagePath,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['item_name'] = Variable<String>(itemName);
    map['image_path'] = Variable<String>(imagePath);
    map['note'] = Variable<String>(note);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      customerId: Value(customerId),
      date: Value(date),
      amount: Value(amount),
      type: Value(type),
      itemName: Value(itemName),
      imagePath: Value(imagePath),
      note: Value(note),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      itemName: serializer.fromJson<String>(json['itemName']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'customerId': serializer.toJson<String>(customerId),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'itemName': serializer.toJson<String>(itemName),
      'imagePath': serializer.toJson<String>(imagePath),
      'note': serializer.toJson<String>(note),
    };
  }

  LedgerEntry copyWith({
    int? id,
    String? customerId,
    String? date,
    double? amount,
    String? type,
    String? itemName,
    String? imagePath,
    String? note,
  }) => LedgerEntry(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    itemName: itemName ?? this.itemName,
    imagePath: imagePath ?? this.imagePath,
    note: note ?? this.note,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('itemName: $itemName, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    date,
    amount,
    type,
    itemName,
    imagePath,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.itemName == this.itemName &&
          other.imagePath == this.imagePath &&
          other.note == this.note);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<String> customerId;
  final Value<String> date;
  final Value<double> amount;
  final Value<String> type;
  final Value<String> itemName;
  final Value<String> imagePath;
  final Value<String> note;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.itemName = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String customerId,
    required String date,
    required double amount,
    required String type,
    this.itemName = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.note = const Value.absent(),
  }) : customerId = Value(customerId),
       date = Value(date),
       amount = Value(amount),
       type = Value(type);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<String>? customerId,
    Expression<String>? date,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<String>? itemName,
    Expression<String>? imagePath,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (itemName != null) 'item_name': itemName,
      if (imagePath != null) 'image_path': imagePath,
      if (note != null) 'note': note,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? customerId,
    Value<String>? date,
    Value<double>? amount,
    Value<String>? type,
    Value<String>? itemName,
    Value<String>? imagePath,
    Value<String>? note,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      itemName: itemName ?? this.itemName,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('itemName: $itemName, ')
          ..write('imagePath: $imagePath, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $CustomerPurchasesTable extends CustomerPurchases
    with TableInfo<$CustomerPurchasesTable, CustomerPurchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerPurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    productName,
    price,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerPurchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerPurchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerPurchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $CustomerPurchasesTable createAlias(String alias) {
    return $CustomerPurchasesTable(attachedDatabase, alias);
  }
}

class CustomerPurchase extends DataClass
    implements Insertable<CustomerPurchase> {
  final String id;
  final String customerId;
  final String productName;
  final double price;
  final String date;
  const CustomerPurchase({
    required this.id,
    required this.customerId,
    required this.productName,
    required this.price,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['product_name'] = Variable<String>(productName);
    map['price'] = Variable<double>(price);
    map['date'] = Variable<String>(date);
    return map;
  }

  CustomerPurchasesCompanion toCompanion(bool nullToAbsent) {
    return CustomerPurchasesCompanion(
      id: Value(id),
      customerId: Value(customerId),
      productName: Value(productName),
      price: Value(price),
      date: Value(date),
    );
  }

  factory CustomerPurchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerPurchase(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      productName: serializer.fromJson<String>(json['productName']),
      price: serializer.fromJson<double>(json['price']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'productName': serializer.toJson<String>(productName),
      'price': serializer.toJson<double>(price),
      'date': serializer.toJson<String>(date),
    };
  }

  CustomerPurchase copyWith({
    String? id,
    String? customerId,
    String? productName,
    double? price,
    String? date,
  }) => CustomerPurchase(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    productName: productName ?? this.productName,
    price: price ?? this.price,
    date: date ?? this.date,
  );
  CustomerPurchase copyWithCompanion(CustomerPurchasesCompanion data) {
    return CustomerPurchase(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      price: data.price.present ? data.price.value : this.price,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerPurchase(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('productName: $productName, ')
          ..write('price: $price, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, customerId, productName, price, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerPurchase &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.productName == this.productName &&
          other.price == this.price &&
          other.date == this.date);
}

class CustomerPurchasesCompanion extends UpdateCompanion<CustomerPurchase> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> productName;
  final Value<double> price;
  final Value<String> date;
  final Value<int> rowid;
  const CustomerPurchasesCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.productName = const Value.absent(),
    this.price = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerPurchasesCompanion.insert({
    required String id,
    required String customerId,
    required String productName,
    required double price,
    required String date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       productName = Value(productName),
       price = Value(price),
       date = Value(date);
  static Insertable<CustomerPurchase> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? productName,
    Expression<double>? price,
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (productName != null) 'product_name': productName,
      if (price != null) 'price': price,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerPurchasesCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? productName,
    Value<double>? price,
    Value<String>? date,
    Value<int>? rowid,
  }) {
    return CustomerPurchasesCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerPurchasesCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('productName: $productName, ')
          ..write('price: $price, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerOrdersTable extends CustomerOrders
    with TableInfo<$CustomerOrdersTable, CustomerOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateGivenMeta = const VerificationMeta(
    'dateGiven',
  );
  @override
  late final GeneratedColumn<String> dateGiven = GeneratedColumn<String>(
    'date_given',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateNeededMeta = const VerificationMeta(
    'dateNeeded',
  );
  @override
  late final GeneratedColumn<String> dateNeeded = GeneratedColumn<String>(
    'date_needed',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<String> dateTaken = GeneratedColumn<String>(
    'date_taken',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    description,
    dateGiven,
    dateNeeded,
    status,
    dateTaken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('date_given')) {
      context.handle(
        _dateGivenMeta,
        dateGiven.isAcceptableOrUnknown(data['date_given']!, _dateGivenMeta),
      );
    } else if (isInserting) {
      context.missing(_dateGivenMeta);
    }
    if (data.containsKey('date_needed')) {
      context.handle(
        _dateNeededMeta,
        dateNeeded.isAcceptableOrUnknown(data['date_needed']!, _dateNeededMeta),
      );
    } else if (isInserting) {
      context.missing(_dateNeededMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      dateGiven: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_given'],
      )!,
      dateNeeded: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_needed'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_taken'],
      )!,
    );
  }

  @override
  $CustomerOrdersTable createAlias(String alias) {
    return $CustomerOrdersTable(attachedDatabase, alias);
  }
}

class CustomerOrder extends DataClass implements Insertable<CustomerOrder> {
  final String id;
  final String customerId;
  final String description;
  final String dateGiven;
  final String dateNeeded;
  final String status;
  final String dateTaken;
  const CustomerOrder({
    required this.id,
    required this.customerId,
    required this.description,
    required this.dateGiven,
    required this.dateNeeded,
    required this.status,
    required this.dateTaken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['description'] = Variable<String>(description);
    map['date_given'] = Variable<String>(dateGiven);
    map['date_needed'] = Variable<String>(dateNeeded);
    map['status'] = Variable<String>(status);
    map['date_taken'] = Variable<String>(dateTaken);
    return map;
  }

  CustomerOrdersCompanion toCompanion(bool nullToAbsent) {
    return CustomerOrdersCompanion(
      id: Value(id),
      customerId: Value(customerId),
      description: Value(description),
      dateGiven: Value(dateGiven),
      dateNeeded: Value(dateNeeded),
      status: Value(status),
      dateTaken: Value(dateTaken),
    );
  }

  factory CustomerOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerOrder(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      description: serializer.fromJson<String>(json['description']),
      dateGiven: serializer.fromJson<String>(json['dateGiven']),
      dateNeeded: serializer.fromJson<String>(json['dateNeeded']),
      status: serializer.fromJson<String>(json['status']),
      dateTaken: serializer.fromJson<String>(json['dateTaken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'description': serializer.toJson<String>(description),
      'dateGiven': serializer.toJson<String>(dateGiven),
      'dateNeeded': serializer.toJson<String>(dateNeeded),
      'status': serializer.toJson<String>(status),
      'dateTaken': serializer.toJson<String>(dateTaken),
    };
  }

  CustomerOrder copyWith({
    String? id,
    String? customerId,
    String? description,
    String? dateGiven,
    String? dateNeeded,
    String? status,
    String? dateTaken,
  }) => CustomerOrder(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    description: description ?? this.description,
    dateGiven: dateGiven ?? this.dateGiven,
    dateNeeded: dateNeeded ?? this.dateNeeded,
    status: status ?? this.status,
    dateTaken: dateTaken ?? this.dateTaken,
  );
  CustomerOrder copyWithCompanion(CustomerOrdersCompanion data) {
    return CustomerOrder(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      description: data.description.present
          ? data.description.value
          : this.description,
      dateGiven: data.dateGiven.present ? data.dateGiven.value : this.dateGiven,
      dateNeeded: data.dateNeeded.present
          ? data.dateNeeded.value
          : this.dateNeeded,
      status: data.status.present ? data.status.value : this.status,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerOrder(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('description: $description, ')
          ..write('dateGiven: $dateGiven, ')
          ..write('dateNeeded: $dateNeeded, ')
          ..write('status: $status, ')
          ..write('dateTaken: $dateTaken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    description,
    dateGiven,
    dateNeeded,
    status,
    dateTaken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerOrder &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.description == this.description &&
          other.dateGiven == this.dateGiven &&
          other.dateNeeded == this.dateNeeded &&
          other.status == this.status &&
          other.dateTaken == this.dateTaken);
}

class CustomerOrdersCompanion extends UpdateCompanion<CustomerOrder> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> description;
  final Value<String> dateGiven;
  final Value<String> dateNeeded;
  final Value<String> status;
  final Value<String> dateTaken;
  final Value<int> rowid;
  const CustomerOrdersCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.description = const Value.absent(),
    this.dateGiven = const Value.absent(),
    this.dateNeeded = const Value.absent(),
    this.status = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerOrdersCompanion.insert({
    required String id,
    required String customerId,
    required String description,
    required String dateGiven,
    required String dateNeeded,
    this.status = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       description = Value(description),
       dateGiven = Value(dateGiven),
       dateNeeded = Value(dateNeeded);
  static Insertable<CustomerOrder> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? description,
    Expression<String>? dateGiven,
    Expression<String>? dateNeeded,
    Expression<String>? status,
    Expression<String>? dateTaken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (description != null) 'description': description,
      if (dateGiven != null) 'date_given': dateGiven,
      if (dateNeeded != null) 'date_needed': dateNeeded,
      if (status != null) 'status': status,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? description,
    Value<String>? dateGiven,
    Value<String>? dateNeeded,
    Value<String>? status,
    Value<String>? dateTaken,
    Value<int>? rowid,
  }) {
    return CustomerOrdersCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      description: description ?? this.description,
      dateGiven: dateGiven ?? this.dateGiven,
      dateNeeded: dateNeeded ?? this.dateNeeded,
      status: status ?? this.status,
      dateTaken: dateTaken ?? this.dateTaken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dateGiven.present) {
      map['date_given'] = Variable<String>(dateGiven.value);
    }
    if (dateNeeded.present) {
      map['date_needed'] = Variable<String>(dateNeeded.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<String>(dateTaken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerOrdersCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('description: $description, ')
          ..write('dateGiven: $dateGiven, ')
          ..write('dateNeeded: $dateNeeded, ')
          ..write('status: $status, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('misc'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billPathMeta = const VerificationMeta(
    'billPath',
  );
  @override
  late final GeneratedColumn<String> billPath = GeneratedColumn<String>(
    'bill_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Cash'),
  );
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
    'is_paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurringTypeMeta = const VerificationMeta(
    'recurringType',
  );
  @override
  late final GeneratedColumn<String> recurringType = GeneratedColumn<String>(
    'recurring_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    amount,
    date,
    billPath,
    dueDay,
    note,
    vendor,
    paymentMethod,
    isPaid,
    recurringType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bill_path')) {
      context.handle(
        _billPathMeta,
        billPath.isAcceptableOrUnknown(data['bill_path']!, _billPathMeta),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('is_paid')) {
      context.handle(
        _isPaidMeta,
        isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta),
      );
    }
    if (data.containsKey('recurring_type')) {
      context.handle(
        _recurringTypeMeta,
        recurringType.isAcceptableOrUnknown(
          data['recurring_type']!,
          _recurringTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      billPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_path'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      isPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paid'],
      )!,
      recurringType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_type'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String type;
  final String title;
  final double amount;
  final String date;
  final String billPath;
  final int? dueDay;
  final String note;
  final String vendor;
  final String paymentMethod;
  final bool isPaid;
  final String recurringType;
  const Expense({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    required this.billPath,
    this.dueDay,
    required this.note,
    required this.vendor,
    required this.paymentMethod,
    required this.isPaid,
    required this.recurringType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<String>(date);
    map['bill_path'] = Variable<String>(billPath);
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    map['note'] = Variable<String>(note);
    map['vendor'] = Variable<String>(vendor);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['is_paid'] = Variable<bool>(isPaid);
    map['recurring_type'] = Variable<String>(recurringType);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      amount: Value(amount),
      date: Value(date),
      billPath: Value(billPath),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      note: Value(note),
      vendor: Value(vendor),
      paymentMethod: Value(paymentMethod),
      isPaid: Value(isPaid),
      recurringType: Value(recurringType),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      billPath: serializer.fromJson<String>(json['billPath']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      note: serializer.fromJson<String>(json['note']),
      vendor: serializer.fromJson<String>(json['vendor']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
      recurringType: serializer.fromJson<String>(json['recurringType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<String>(date),
      'billPath': serializer.toJson<String>(billPath),
      'dueDay': serializer.toJson<int?>(dueDay),
      'note': serializer.toJson<String>(note),
      'vendor': serializer.toJson<String>(vendor),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'isPaid': serializer.toJson<bool>(isPaid),
      'recurringType': serializer.toJson<String>(recurringType),
    };
  }

  Expense copyWith({
    String? id,
    String? type,
    String? title,
    double? amount,
    String? date,
    String? billPath,
    Value<int?> dueDay = const Value.absent(),
    String? note,
    String? vendor,
    String? paymentMethod,
    bool? isPaid,
    String? recurringType,
  }) => Expense(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    billPath: billPath ?? this.billPath,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    note: note ?? this.note,
    vendor: vendor ?? this.vendor,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    isPaid: isPaid ?? this.isPaid,
    recurringType: recurringType ?? this.recurringType,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      billPath: data.billPath.present ? data.billPath.value : this.billPath,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      note: data.note.present ? data.note.value : this.note,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
      recurringType: data.recurringType.present
          ? data.recurringType.value
          : this.recurringType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('billPath: $billPath, ')
          ..write('dueDay: $dueDay, ')
          ..write('note: $note, ')
          ..write('vendor: $vendor, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('isPaid: $isPaid, ')
          ..write('recurringType: $recurringType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    amount,
    date,
    billPath,
    dueDay,
    note,
    vendor,
    paymentMethod,
    isPaid,
    recurringType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.billPath == this.billPath &&
          other.dueDay == this.dueDay &&
          other.note == this.note &&
          other.vendor == this.vendor &&
          other.paymentMethod == this.paymentMethod &&
          other.isPaid == this.isPaid &&
          other.recurringType == this.recurringType);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<double> amount;
  final Value<String> date;
  final Value<String> billPath;
  final Value<int?> dueDay;
  final Value<String> note;
  final Value<String> vendor;
  final Value<String> paymentMethod;
  final Value<bool> isPaid;
  final Value<String> recurringType;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.billPath = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.note = const Value.absent(),
    this.vendor = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.recurringType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    this.type = const Value.absent(),
    required String title,
    required double amount,
    required String date,
    this.billPath = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.note = const Value.absent(),
    this.vendor = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.recurringType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       amount = Value(amount),
       date = Value(date);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<double>? amount,
    Expression<String>? date,
    Expression<String>? billPath,
    Expression<int>? dueDay,
    Expression<String>? note,
    Expression<String>? vendor,
    Expression<String>? paymentMethod,
    Expression<bool>? isPaid,
    Expression<String>? recurringType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (billPath != null) 'bill_path': billPath,
      if (dueDay != null) 'due_day': dueDay,
      if (note != null) 'note': note,
      if (vendor != null) 'vendor': vendor,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (isPaid != null) 'is_paid': isPaid,
      if (recurringType != null) 'recurring_type': recurringType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<double>? amount,
    Value<String>? date,
    Value<String>? billPath,
    Value<int?>? dueDay,
    Value<String>? note,
    Value<String>? vendor,
    Value<String>? paymentMethod,
    Value<bool>? isPaid,
    Value<String>? recurringType,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      billPath: billPath ?? this.billPath,
      dueDay: dueDay ?? this.dueDay,
      note: note ?? this.note,
      vendor: vendor ?? this.vendor,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      recurringType: recurringType ?? this.recurringType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (billPath.present) {
      map['bill_path'] = Variable<String>(billPath.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (recurringType.present) {
      map['recurring_type'] = Variable<String>(recurringType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('billPath: $billPath, ')
          ..write('dueDay: $dueDay, ')
          ..write('note: $note, ')
          ..write('vendor: $vendor, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('isPaid: $isPaid, ')
          ..write('recurringType: $recurringType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases
    with TableInfo<$PurchasesTable, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _cashTakenMeta = const VerificationMeta(
    'cashTaken',
  );
  @override
  late final GeneratedColumn<double> cashTaken = GeneratedColumn<double>(
    'cash_taken',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _investorIdMeta = const VerificationMeta(
    'investorId',
  );
  @override
  late final GeneratedColumn<String> investorId = GeneratedColumn<String>(
    'investor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoPhotoPathMeta = const VerificationMeta(
    'memoPhotoPath',
  );
  @override
  late final GeneratedColumn<String> memoPhotoPath = GeneratedColumn<String>(
    'memo_photo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _returnedCashMeta = const VerificationMeta(
    'returnedCash',
  );
  @override
  late final GeneratedColumn<double> returnedCash = GeneratedColumn<double>(
    'returned_cash',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    source,
    cashTaken,
    investorId,
    notes,
    memoPhotoPath,
    returnedCash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<Purchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('cash_taken')) {
      context.handle(
        _cashTakenMeta,
        cashTaken.isAcceptableOrUnknown(data['cash_taken']!, _cashTakenMeta),
      );
    }
    if (data.containsKey('investor_id')) {
      context.handle(
        _investorIdMeta,
        investorId.isAcceptableOrUnknown(data['investor_id']!, _investorIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('memo_photo_path')) {
      context.handle(
        _memoPhotoPathMeta,
        memoPhotoPath.isAcceptableOrUnknown(
          data['memo_photo_path']!,
          _memoPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('returned_cash')) {
      context.handle(
        _returnedCashMeta,
        returnedCash.isAcceptableOrUnknown(
          data['returned_cash']!,
          _returnedCashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      cashTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_taken'],
      )!,
      investorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investor_id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      memoPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo_photo_path'],
      )!,
      returnedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}returned_cash'],
      )!,
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final String id;
  final String date;
  final String source;
  final double cashTaken;
  final String investorId;
  final String notes;
  final String memoPhotoPath;
  final double returnedCash;
  const Purchase({
    required this.id,
    required this.date,
    required this.source,
    required this.cashTaken,
    required this.investorId,
    required this.notes,
    required this.memoPhotoPath,
    required this.returnedCash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['source'] = Variable<String>(source);
    map['cash_taken'] = Variable<double>(cashTaken);
    map['investor_id'] = Variable<String>(investorId);
    map['notes'] = Variable<String>(notes);
    map['memo_photo_path'] = Variable<String>(memoPhotoPath);
    map['returned_cash'] = Variable<double>(returnedCash);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      date: Value(date),
      source: Value(source),
      cashTaken: Value(cashTaken),
      investorId: Value(investorId),
      notes: Value(notes),
      memoPhotoPath: Value(memoPhotoPath),
      returnedCash: Value(returnedCash),
    );
  }

  factory Purchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      source: serializer.fromJson<String>(json['source']),
      cashTaken: serializer.fromJson<double>(json['cashTaken']),
      investorId: serializer.fromJson<String>(json['investorId']),
      notes: serializer.fromJson<String>(json['notes']),
      memoPhotoPath: serializer.fromJson<String>(json['memoPhotoPath']),
      returnedCash: serializer.fromJson<double>(json['returnedCash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'source': serializer.toJson<String>(source),
      'cashTaken': serializer.toJson<double>(cashTaken),
      'investorId': serializer.toJson<String>(investorId),
      'notes': serializer.toJson<String>(notes),
      'memoPhotoPath': serializer.toJson<String>(memoPhotoPath),
      'returnedCash': serializer.toJson<double>(returnedCash),
    };
  }

  Purchase copyWith({
    String? id,
    String? date,
    String? source,
    double? cashTaken,
    String? investorId,
    String? notes,
    String? memoPhotoPath,
    double? returnedCash,
  }) => Purchase(
    id: id ?? this.id,
    date: date ?? this.date,
    source: source ?? this.source,
    cashTaken: cashTaken ?? this.cashTaken,
    investorId: investorId ?? this.investorId,
    notes: notes ?? this.notes,
    memoPhotoPath: memoPhotoPath ?? this.memoPhotoPath,
    returnedCash: returnedCash ?? this.returnedCash,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      source: data.source.present ? data.source.value : this.source,
      cashTaken: data.cashTaken.present ? data.cashTaken.value : this.cashTaken,
      investorId: data.investorId.present
          ? data.investorId.value
          : this.investorId,
      notes: data.notes.present ? data.notes.value : this.notes,
      memoPhotoPath: data.memoPhotoPath.present
          ? data.memoPhotoPath.value
          : this.memoPhotoPath,
      returnedCash: data.returnedCash.present
          ? data.returnedCash.value
          : this.returnedCash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('source: $source, ')
          ..write('cashTaken: $cashTaken, ')
          ..write('investorId: $investorId, ')
          ..write('notes: $notes, ')
          ..write('memoPhotoPath: $memoPhotoPath, ')
          ..write('returnedCash: $returnedCash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    source,
    cashTaken,
    investorId,
    notes,
    memoPhotoPath,
    returnedCash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.date == this.date &&
          other.source == this.source &&
          other.cashTaken == this.cashTaken &&
          other.investorId == this.investorId &&
          other.notes == this.notes &&
          other.memoPhotoPath == this.memoPhotoPath &&
          other.returnedCash == this.returnedCash);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> source;
  final Value<double> cashTaken;
  final Value<String> investorId;
  final Value<String> notes;
  final Value<String> memoPhotoPath;
  final Value<double> returnedCash;
  final Value<int> rowid;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.source = const Value.absent(),
    this.cashTaken = const Value.absent(),
    this.investorId = const Value.absent(),
    this.notes = const Value.absent(),
    this.memoPhotoPath = const Value.absent(),
    this.returnedCash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasesCompanion.insert({
    required String id,
    required String date,
    this.source = const Value.absent(),
    this.cashTaken = const Value.absent(),
    this.investorId = const Value.absent(),
    this.notes = const Value.absent(),
    this.memoPhotoPath = const Value.absent(),
    this.returnedCash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date);
  static Insertable<Purchase> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? source,
    Expression<double>? cashTaken,
    Expression<String>? investorId,
    Expression<String>? notes,
    Expression<String>? memoPhotoPath,
    Expression<double>? returnedCash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (source != null) 'source': source,
      if (cashTaken != null) 'cash_taken': cashTaken,
      if (investorId != null) 'investor_id': investorId,
      if (notes != null) 'notes': notes,
      if (memoPhotoPath != null) 'memo_photo_path': memoPhotoPath,
      if (returnedCash != null) 'returned_cash': returnedCash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasesCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? source,
    Value<double>? cashTaken,
    Value<String>? investorId,
    Value<String>? notes,
    Value<String>? memoPhotoPath,
    Value<double>? returnedCash,
    Value<int>? rowid,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      source: source ?? this.source,
      cashTaken: cashTaken ?? this.cashTaken,
      investorId: investorId ?? this.investorId,
      notes: notes ?? this.notes,
      memoPhotoPath: memoPhotoPath ?? this.memoPhotoPath,
      returnedCash: returnedCash ?? this.returnedCash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (cashTaken.present) {
      map['cash_taken'] = Variable<double>(cashTaken.value);
    }
    if (investorId.present) {
      map['investor_id'] = Variable<String>(investorId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (memoPhotoPath.present) {
      map['memo_photo_path'] = Variable<String>(memoPhotoPath.value);
    }
    if (returnedCash.present) {
      map['returned_cash'] = Variable<double>(returnedCash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('source: $source, ')
          ..write('cashTaken: $cashTaken, ')
          ..write('investorId: $investorId, ')
          ..write('notes: $notes, ')
          ..write('memoPhotoPath: $memoPhotoPath, ')
          ..write('returnedCash: $returnedCash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseItemsTable extends PurchaseItems
    with TableInfo<$PurchaseItemsTable, PurchaseItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shopNameMeta = const VerificationMeta(
    'shopName',
  );
  @override
  late final GeneratedColumn<String> shopName = GeneratedColumn<String>(
    'shop_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    purchaseId,
    shopName,
    itemName,
    quantity,
    unitPrice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
        _purchaseIdMeta,
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('shop_name')) {
      context.handle(
        _shopNameMeta,
        shopName.isAcceptableOrUnknown(data['shop_name']!, _shopNameMeta),
      );
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      )!,
      shopName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_name'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
    );
  }

  @override
  $PurchaseItemsTable createAlias(String alias) {
    return $PurchaseItemsTable(attachedDatabase, alias);
  }
}

class PurchaseItem extends DataClass implements Insertable<PurchaseItem> {
  final int id;
  final String purchaseId;
  final String shopName;
  final String itemName;
  final double quantity;
  final double unitPrice;
  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.shopName,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['purchase_id'] = Variable<String>(purchaseId);
    map['shop_name'] = Variable<String>(shopName);
    map['item_name'] = Variable<String>(itemName);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    return map;
  }

  PurchaseItemsCompanion toCompanion(bool nullToAbsent) {
    return PurchaseItemsCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      shopName: Value(shopName),
      itemName: Value(itemName),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
    );
  }

  factory PurchaseItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseItem(
      id: serializer.fromJson<int>(json['id']),
      purchaseId: serializer.fromJson<String>(json['purchaseId']),
      shopName: serializer.fromJson<String>(json['shopName']),
      itemName: serializer.fromJson<String>(json['itemName']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'purchaseId': serializer.toJson<String>(purchaseId),
      'shopName': serializer.toJson<String>(shopName),
      'itemName': serializer.toJson<String>(itemName),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
    };
  }

  PurchaseItem copyWith({
    int? id,
    String? purchaseId,
    String? shopName,
    String? itemName,
    double? quantity,
    double? unitPrice,
  }) => PurchaseItem(
    id: id ?? this.id,
    purchaseId: purchaseId ?? this.purchaseId,
    shopName: shopName ?? this.shopName,
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
  );
  PurchaseItem copyWithCompanion(PurchaseItemsCompanion data) {
    return PurchaseItem(
      id: data.id.present ? data.id.value : this.id,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      shopName: data.shopName.present ? data.shopName.value : this.shopName,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseItem(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('shopName: $shopName, ')
          ..write('itemName: $itemName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, purchaseId, shopName, itemName, quantity, unitPrice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseItem &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.shopName == this.shopName &&
          other.itemName == this.itemName &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice);
}

class PurchaseItemsCompanion extends UpdateCompanion<PurchaseItem> {
  final Value<int> id;
  final Value<String> purchaseId;
  final Value<String> shopName;
  final Value<String> itemName;
  final Value<double> quantity;
  final Value<double> unitPrice;
  const PurchaseItemsCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.shopName = const Value.absent(),
    this.itemName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
  });
  PurchaseItemsCompanion.insert({
    this.id = const Value.absent(),
    required String purchaseId,
    this.shopName = const Value.absent(),
    required String itemName,
    required double quantity,
    required double unitPrice,
  }) : purchaseId = Value(purchaseId),
       itemName = Value(itemName),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice);
  static Insertable<PurchaseItem> custom({
    Expression<int>? id,
    Expression<String>? purchaseId,
    Expression<String>? shopName,
    Expression<String>? itemName,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (shopName != null) 'shop_name': shopName,
      if (itemName != null) 'item_name': itemName,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
    });
  }

  PurchaseItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? purchaseId,
    Value<String>? shopName,
    Value<String>? itemName,
    Value<double>? quantity,
    Value<double>? unitPrice,
  }) {
    return PurchaseItemsCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      shopName: shopName ?? this.shopName,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (shopName.present) {
      map['shop_name'] = Variable<String>(shopName.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseItemsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('shopName: $shopName, ')
          ..write('itemName: $itemName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice')
          ..write(')'))
        .toString();
  }
}

class $TransportCostsTable extends TransportCosts
    with TableInfo<$TransportCostsTable, TransportCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransportCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleMeta = const VerificationMeta(
    'vehicle',
  );
  @override
  late final GeneratedColumn<String> vehicle = GeneratedColumn<String>(
    'vehicle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, purchaseId, vehicle, cost];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transport_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransportCost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
        _purchaseIdMeta,
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('vehicle')) {
      context.handle(
        _vehicleMeta,
        vehicle.isAcceptableOrUnknown(data['vehicle']!, _vehicleMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransportCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransportCost(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      )!,
      vehicle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
    );
  }

  @override
  $TransportCostsTable createAlias(String alias) {
    return $TransportCostsTable(attachedDatabase, alias);
  }
}

class TransportCost extends DataClass implements Insertable<TransportCost> {
  final int id;
  final String purchaseId;
  final String vehicle;
  final double cost;
  const TransportCost({
    required this.id,
    required this.purchaseId,
    required this.vehicle,
    required this.cost,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['purchase_id'] = Variable<String>(purchaseId);
    map['vehicle'] = Variable<String>(vehicle);
    map['cost'] = Variable<double>(cost);
    return map;
  }

  TransportCostsCompanion toCompanion(bool nullToAbsent) {
    return TransportCostsCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      vehicle: Value(vehicle),
      cost: Value(cost),
    );
  }

  factory TransportCost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransportCost(
      id: serializer.fromJson<int>(json['id']),
      purchaseId: serializer.fromJson<String>(json['purchaseId']),
      vehicle: serializer.fromJson<String>(json['vehicle']),
      cost: serializer.fromJson<double>(json['cost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'purchaseId': serializer.toJson<String>(purchaseId),
      'vehicle': serializer.toJson<String>(vehicle),
      'cost': serializer.toJson<double>(cost),
    };
  }

  TransportCost copyWith({
    int? id,
    String? purchaseId,
    String? vehicle,
    double? cost,
  }) => TransportCost(
    id: id ?? this.id,
    purchaseId: purchaseId ?? this.purchaseId,
    vehicle: vehicle ?? this.vehicle,
    cost: cost ?? this.cost,
  );
  TransportCost copyWithCompanion(TransportCostsCompanion data) {
    return TransportCost(
      id: data.id.present ? data.id.value : this.id,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      vehicle: data.vehicle.present ? data.vehicle.value : this.vehicle,
      cost: data.cost.present ? data.cost.value : this.cost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransportCost(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('vehicle: $vehicle, ')
          ..write('cost: $cost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, purchaseId, vehicle, cost);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransportCost &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.vehicle == this.vehicle &&
          other.cost == this.cost);
}

class TransportCostsCompanion extends UpdateCompanion<TransportCost> {
  final Value<int> id;
  final Value<String> purchaseId;
  final Value<String> vehicle;
  final Value<double> cost;
  const TransportCostsCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.vehicle = const Value.absent(),
    this.cost = const Value.absent(),
  });
  TransportCostsCompanion.insert({
    this.id = const Value.absent(),
    required String purchaseId,
    required String vehicle,
    required double cost,
  }) : purchaseId = Value(purchaseId),
       vehicle = Value(vehicle),
       cost = Value(cost);
  static Insertable<TransportCost> custom({
    Expression<int>? id,
    Expression<String>? purchaseId,
    Expression<String>? vehicle,
    Expression<double>? cost,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (vehicle != null) 'vehicle': vehicle,
      if (cost != null) 'cost': cost,
    });
  }

  TransportCostsCompanion copyWith({
    Value<int>? id,
    Value<String>? purchaseId,
    Value<String>? vehicle,
    Value<double>? cost,
  }) {
    return TransportCostsCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      vehicle: vehicle ?? this.vehicle,
      cost: cost ?? this.cost,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (vehicle.present) {
      map['vehicle'] = Variable<String>(vehicle.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransportCostsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('vehicle: $vehicle, ')
          ..write('cost: $cost')
          ..write(')'))
        .toString();
  }
}

class $OtherCostsTable extends OtherCosts
    with TableInfo<$OtherCostsTable, OtherCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OtherCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, purchaseId, description, cost];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'other_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OtherCost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
        _purchaseIdMeta,
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OtherCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OtherCost(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
    );
  }

  @override
  $OtherCostsTable createAlias(String alias) {
    return $OtherCostsTable(attachedDatabase, alias);
  }
}

class OtherCost extends DataClass implements Insertable<OtherCost> {
  final int id;
  final String purchaseId;
  final String description;
  final double cost;
  const OtherCost({
    required this.id,
    required this.purchaseId,
    required this.description,
    required this.cost,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['purchase_id'] = Variable<String>(purchaseId);
    map['description'] = Variable<String>(description);
    map['cost'] = Variable<double>(cost);
    return map;
  }

  OtherCostsCompanion toCompanion(bool nullToAbsent) {
    return OtherCostsCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      description: Value(description),
      cost: Value(cost),
    );
  }

  factory OtherCost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OtherCost(
      id: serializer.fromJson<int>(json['id']),
      purchaseId: serializer.fromJson<String>(json['purchaseId']),
      description: serializer.fromJson<String>(json['description']),
      cost: serializer.fromJson<double>(json['cost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'purchaseId': serializer.toJson<String>(purchaseId),
      'description': serializer.toJson<String>(description),
      'cost': serializer.toJson<double>(cost),
    };
  }

  OtherCost copyWith({
    int? id,
    String? purchaseId,
    String? description,
    double? cost,
  }) => OtherCost(
    id: id ?? this.id,
    purchaseId: purchaseId ?? this.purchaseId,
    description: description ?? this.description,
    cost: cost ?? this.cost,
  );
  OtherCost copyWithCompanion(OtherCostsCompanion data) {
    return OtherCost(
      id: data.id.present ? data.id.value : this.id,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      description: data.description.present
          ? data.description.value
          : this.description,
      cost: data.cost.present ? data.cost.value : this.cost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OtherCost(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('description: $description, ')
          ..write('cost: $cost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, purchaseId, description, cost);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OtherCost &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.description == this.description &&
          other.cost == this.cost);
}

class OtherCostsCompanion extends UpdateCompanion<OtherCost> {
  final Value<int> id;
  final Value<String> purchaseId;
  final Value<String> description;
  final Value<double> cost;
  const OtherCostsCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.description = const Value.absent(),
    this.cost = const Value.absent(),
  });
  OtherCostsCompanion.insert({
    this.id = const Value.absent(),
    required String purchaseId,
    required String description,
    required double cost,
  }) : purchaseId = Value(purchaseId),
       description = Value(description),
       cost = Value(cost);
  static Insertable<OtherCost> custom({
    Expression<int>? id,
    Expression<String>? purchaseId,
    Expression<String>? description,
    Expression<double>? cost,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (description != null) 'description': description,
      if (cost != null) 'cost': cost,
    });
  }

  OtherCostsCompanion copyWith({
    Value<int>? id,
    Value<String>? purchaseId,
    Value<String>? description,
    Value<double>? cost,
  }) {
    return OtherCostsCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      description: description ?? this.description,
      cost: cost ?? this.cost,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OtherCostsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('description: $description, ')
          ..write('cost: $cost')
          ..write(')'))
        .toString();
  }
}

class $InvestorsTable extends Investors
    with TableInfo<$InvestorsTable, Investor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _investedAmountMeta = const VerificationMeta(
    'investedAmount',
  );
  @override
  late final GeneratedColumn<double> investedAmount = GeneratedColumn<double>(
    'invested_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMonthsMeta = const VerificationMeta(
    'durationMonths',
  );
  @override
  late final GeneratedColumn<int> durationMonths = GeneratedColumn<int>(
    'duration_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  static const VerificationMeta _profitPercentageMeta = const VerificationMeta(
    'profitPercentage',
  );
  @override
  late final GeneratedColumn<double> profitPercentage = GeneratedColumn<double>(
    'profit_percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dailyEarningsMeta = const VerificationMeta(
    'dailyEarnings',
  );
  @override
  late final GeneratedColumn<double> dailyEarnings = GeneratedColumn<double>(
    'daily_earnings',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _monthlyEarningsMeta = const VerificationMeta(
    'monthlyEarnings',
  );
  @override
  late final GeneratedColumn<double> monthlyEarnings = GeneratedColumn<double>(
    'monthly_earnings',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contractTypeMeta = const VerificationMeta(
    'contractType',
  );
  @override
  late final GeneratedColumn<String> contractType = GeneratedColumn<String>(
    'contract_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('profitShare'),
  );
  static const VerificationMeta _investmentTypeMeta = const VerificationMeta(
    'investmentType',
  );
  @override
  late final GeneratedColumn<String> investmentType = GeneratedColumn<String>(
    'investment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalBoughtMeta = const VerificationMeta(
    'totalBought',
  );
  @override
  late final GeneratedColumn<double> totalBought = GeneratedColumn<double>(
    'total_bought',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalSoldMeta = const VerificationMeta(
    'totalSold',
  );
  @override
  late final GeneratedColumn<double> totalSold = GeneratedColumn<double>(
    'total_sold',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalProfitMeta = const VerificationMeta(
    'totalProfit',
  );
  @override
  late final GeneratedColumn<double> totalProfit = GeneratedColumn<double>(
    'total_profit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingBalanceMeta = const VerificationMeta(
    'remainingBalance',
  );
  @override
  late final GeneratedColumn<double> remainingBalance = GeneratedColumn<double>(
    'remaining_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _productValueTotalMeta = const VerificationMeta(
    'productValueTotal',
  );
  @override
  late final GeneratedColumn<double> productValueTotal =
      GeneratedColumn<double>(
        'product_value_total',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _cashInvestedMeta = const VerificationMeta(
    'cashInvested',
  );
  @override
  late final GeneratedColumn<double> cashInvested = GeneratedColumn<double>(
    'cash_invested',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _productInvestedMeta = const VerificationMeta(
    'productInvested',
  );
  @override
  late final GeneratedColumn<double> productInvested = GeneratedColumn<double>(
    'product_invested',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    investedAmount,
    durationMonths,
    profitPercentage,
    dailyEarnings,
    monthlyEarnings,
    contractType,
    investmentType,
    isActive,
    startDate,
    totalBought,
    totalSold,
    totalProfit,
    remainingBalance,
    productValueTotal,
    cashInvested,
    productInvested,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investors';
  @override
  VerificationContext validateIntegrity(
    Insertable<Investor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('invested_amount')) {
      context.handle(
        _investedAmountMeta,
        investedAmount.isAcceptableOrUnknown(
          data['invested_amount']!,
          _investedAmountMeta,
        ),
      );
    }
    if (data.containsKey('duration_months')) {
      context.handle(
        _durationMonthsMeta,
        durationMonths.isAcceptableOrUnknown(
          data['duration_months']!,
          _durationMonthsMeta,
        ),
      );
    }
    if (data.containsKey('profit_percentage')) {
      context.handle(
        _profitPercentageMeta,
        profitPercentage.isAcceptableOrUnknown(
          data['profit_percentage']!,
          _profitPercentageMeta,
        ),
      );
    }
    if (data.containsKey('daily_earnings')) {
      context.handle(
        _dailyEarningsMeta,
        dailyEarnings.isAcceptableOrUnknown(
          data['daily_earnings']!,
          _dailyEarningsMeta,
        ),
      );
    }
    if (data.containsKey('monthly_earnings')) {
      context.handle(
        _monthlyEarningsMeta,
        monthlyEarnings.isAcceptableOrUnknown(
          data['monthly_earnings']!,
          _monthlyEarningsMeta,
        ),
      );
    }
    if (data.containsKey('contract_type')) {
      context.handle(
        _contractTypeMeta,
        contractType.isAcceptableOrUnknown(
          data['contract_type']!,
          _contractTypeMeta,
        ),
      );
    }
    if (data.containsKey('investment_type')) {
      context.handle(
        _investmentTypeMeta,
        investmentType.isAcceptableOrUnknown(
          data['investment_type']!,
          _investmentTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('total_bought')) {
      context.handle(
        _totalBoughtMeta,
        totalBought.isAcceptableOrUnknown(
          data['total_bought']!,
          _totalBoughtMeta,
        ),
      );
    }
    if (data.containsKey('total_sold')) {
      context.handle(
        _totalSoldMeta,
        totalSold.isAcceptableOrUnknown(data['total_sold']!, _totalSoldMeta),
      );
    }
    if (data.containsKey('total_profit')) {
      context.handle(
        _totalProfitMeta,
        totalProfit.isAcceptableOrUnknown(
          data['total_profit']!,
          _totalProfitMeta,
        ),
      );
    }
    if (data.containsKey('remaining_balance')) {
      context.handle(
        _remainingBalanceMeta,
        remainingBalance.isAcceptableOrUnknown(
          data['remaining_balance']!,
          _remainingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('product_value_total')) {
      context.handle(
        _productValueTotalMeta,
        productValueTotal.isAcceptableOrUnknown(
          data['product_value_total']!,
          _productValueTotalMeta,
        ),
      );
    }
    if (data.containsKey('cash_invested')) {
      context.handle(
        _cashInvestedMeta,
        cashInvested.isAcceptableOrUnknown(
          data['cash_invested']!,
          _cashInvestedMeta,
        ),
      );
    }
    if (data.containsKey('product_invested')) {
      context.handle(
        _productInvestedMeta,
        productInvested.isAcceptableOrUnknown(
          data['product_invested']!,
          _productInvestedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Investor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Investor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      investedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}invested_amount'],
      )!,
      durationMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_months'],
      )!,
      profitPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_percentage'],
      )!,
      dailyEarnings: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daily_earnings'],
      )!,
      monthlyEarnings: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_earnings'],
      )!,
      contractType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_type'],
      )!,
      investmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investment_type'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      totalBought: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_bought'],
      )!,
      totalSold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_sold'],
      )!,
      totalProfit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_profit'],
      )!,
      remainingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_balance'],
      )!,
      productValueTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}product_value_total'],
      )!,
      cashInvested: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_invested'],
      )!,
      productInvested: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}product_invested'],
      )!,
    );
  }

  @override
  $InvestorsTable createAlias(String alias) {
    return $InvestorsTable(attachedDatabase, alias);
  }
}

class Investor extends DataClass implements Insertable<Investor> {
  final String id;
  final String name;
  final double investedAmount;
  final int durationMonths;
  final double profitPercentage;
  final double dailyEarnings;
  final double monthlyEarnings;
  final String contractType;
  final String investmentType;
  final bool isActive;
  final String startDate;
  final double totalBought;
  final double totalSold;
  final double totalProfit;
  final double remainingBalance;
  final double productValueTotal;
  final double cashInvested;
  final double productInvested;
  const Investor({
    required this.id,
    required this.name,
    required this.investedAmount,
    required this.durationMonths,
    required this.profitPercentage,
    required this.dailyEarnings,
    required this.monthlyEarnings,
    required this.contractType,
    required this.investmentType,
    required this.isActive,
    required this.startDate,
    required this.totalBought,
    required this.totalSold,
    required this.totalProfit,
    required this.remainingBalance,
    required this.productValueTotal,
    required this.cashInvested,
    required this.productInvested,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['invested_amount'] = Variable<double>(investedAmount);
    map['duration_months'] = Variable<int>(durationMonths);
    map['profit_percentage'] = Variable<double>(profitPercentage);
    map['daily_earnings'] = Variable<double>(dailyEarnings);
    map['monthly_earnings'] = Variable<double>(monthlyEarnings);
    map['contract_type'] = Variable<String>(contractType);
    map['investment_type'] = Variable<String>(investmentType);
    map['is_active'] = Variable<bool>(isActive);
    map['start_date'] = Variable<String>(startDate);
    map['total_bought'] = Variable<double>(totalBought);
    map['total_sold'] = Variable<double>(totalSold);
    map['total_profit'] = Variable<double>(totalProfit);
    map['remaining_balance'] = Variable<double>(remainingBalance);
    map['product_value_total'] = Variable<double>(productValueTotal);
    map['cash_invested'] = Variable<double>(cashInvested);
    map['product_invested'] = Variable<double>(productInvested);
    return map;
  }

  InvestorsCompanion toCompanion(bool nullToAbsent) {
    return InvestorsCompanion(
      id: Value(id),
      name: Value(name),
      investedAmount: Value(investedAmount),
      durationMonths: Value(durationMonths),
      profitPercentage: Value(profitPercentage),
      dailyEarnings: Value(dailyEarnings),
      monthlyEarnings: Value(monthlyEarnings),
      contractType: Value(contractType),
      investmentType: Value(investmentType),
      isActive: Value(isActive),
      startDate: Value(startDate),
      totalBought: Value(totalBought),
      totalSold: Value(totalSold),
      totalProfit: Value(totalProfit),
      remainingBalance: Value(remainingBalance),
      productValueTotal: Value(productValueTotal),
      cashInvested: Value(cashInvested),
      productInvested: Value(productInvested),
    );
  }

  factory Investor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Investor(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      investedAmount: serializer.fromJson<double>(json['investedAmount']),
      durationMonths: serializer.fromJson<int>(json['durationMonths']),
      profitPercentage: serializer.fromJson<double>(json['profitPercentage']),
      dailyEarnings: serializer.fromJson<double>(json['dailyEarnings']),
      monthlyEarnings: serializer.fromJson<double>(json['monthlyEarnings']),
      contractType: serializer.fromJson<String>(json['contractType']),
      investmentType: serializer.fromJson<String>(json['investmentType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      startDate: serializer.fromJson<String>(json['startDate']),
      totalBought: serializer.fromJson<double>(json['totalBought']),
      totalSold: serializer.fromJson<double>(json['totalSold']),
      totalProfit: serializer.fromJson<double>(json['totalProfit']),
      remainingBalance: serializer.fromJson<double>(json['remainingBalance']),
      productValueTotal: serializer.fromJson<double>(json['productValueTotal']),
      cashInvested: serializer.fromJson<double>(json['cashInvested']),
      productInvested: serializer.fromJson<double>(json['productInvested']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'investedAmount': serializer.toJson<double>(investedAmount),
      'durationMonths': serializer.toJson<int>(durationMonths),
      'profitPercentage': serializer.toJson<double>(profitPercentage),
      'dailyEarnings': serializer.toJson<double>(dailyEarnings),
      'monthlyEarnings': serializer.toJson<double>(monthlyEarnings),
      'contractType': serializer.toJson<String>(contractType),
      'investmentType': serializer.toJson<String>(investmentType),
      'isActive': serializer.toJson<bool>(isActive),
      'startDate': serializer.toJson<String>(startDate),
      'totalBought': serializer.toJson<double>(totalBought),
      'totalSold': serializer.toJson<double>(totalSold),
      'totalProfit': serializer.toJson<double>(totalProfit),
      'remainingBalance': serializer.toJson<double>(remainingBalance),
      'productValueTotal': serializer.toJson<double>(productValueTotal),
      'cashInvested': serializer.toJson<double>(cashInvested),
      'productInvested': serializer.toJson<double>(productInvested),
    };
  }

  Investor copyWith({
    String? id,
    String? name,
    double? investedAmount,
    int? durationMonths,
    double? profitPercentage,
    double? dailyEarnings,
    double? monthlyEarnings,
    String? contractType,
    String? investmentType,
    bool? isActive,
    String? startDate,
    double? totalBought,
    double? totalSold,
    double? totalProfit,
    double? remainingBalance,
    double? productValueTotal,
    double? cashInvested,
    double? productInvested,
  }) => Investor(
    id: id ?? this.id,
    name: name ?? this.name,
    investedAmount: investedAmount ?? this.investedAmount,
    durationMonths: durationMonths ?? this.durationMonths,
    profitPercentage: profitPercentage ?? this.profitPercentage,
    dailyEarnings: dailyEarnings ?? this.dailyEarnings,
    monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
    contractType: contractType ?? this.contractType,
    investmentType: investmentType ?? this.investmentType,
    isActive: isActive ?? this.isActive,
    startDate: startDate ?? this.startDate,
    totalBought: totalBought ?? this.totalBought,
    totalSold: totalSold ?? this.totalSold,
    totalProfit: totalProfit ?? this.totalProfit,
    remainingBalance: remainingBalance ?? this.remainingBalance,
    productValueTotal: productValueTotal ?? this.productValueTotal,
    cashInvested: cashInvested ?? this.cashInvested,
    productInvested: productInvested ?? this.productInvested,
  );
  Investor copyWithCompanion(InvestorsCompanion data) {
    return Investor(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      investedAmount: data.investedAmount.present
          ? data.investedAmount.value
          : this.investedAmount,
      durationMonths: data.durationMonths.present
          ? data.durationMonths.value
          : this.durationMonths,
      profitPercentage: data.profitPercentage.present
          ? data.profitPercentage.value
          : this.profitPercentage,
      dailyEarnings: data.dailyEarnings.present
          ? data.dailyEarnings.value
          : this.dailyEarnings,
      monthlyEarnings: data.monthlyEarnings.present
          ? data.monthlyEarnings.value
          : this.monthlyEarnings,
      contractType: data.contractType.present
          ? data.contractType.value
          : this.contractType,
      investmentType: data.investmentType.present
          ? data.investmentType.value
          : this.investmentType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      totalBought: data.totalBought.present
          ? data.totalBought.value
          : this.totalBought,
      totalSold: data.totalSold.present ? data.totalSold.value : this.totalSold,
      totalProfit: data.totalProfit.present
          ? data.totalProfit.value
          : this.totalProfit,
      remainingBalance: data.remainingBalance.present
          ? data.remainingBalance.value
          : this.remainingBalance,
      productValueTotal: data.productValueTotal.present
          ? data.productValueTotal.value
          : this.productValueTotal,
      cashInvested: data.cashInvested.present
          ? data.cashInvested.value
          : this.cashInvested,
      productInvested: data.productInvested.present
          ? data.productInvested.value
          : this.productInvested,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Investor(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('investedAmount: $investedAmount, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('profitPercentage: $profitPercentage, ')
          ..write('dailyEarnings: $dailyEarnings, ')
          ..write('monthlyEarnings: $monthlyEarnings, ')
          ..write('contractType: $contractType, ')
          ..write('investmentType: $investmentType, ')
          ..write('isActive: $isActive, ')
          ..write('startDate: $startDate, ')
          ..write('totalBought: $totalBought, ')
          ..write('totalSold: $totalSold, ')
          ..write('totalProfit: $totalProfit, ')
          ..write('remainingBalance: $remainingBalance, ')
          ..write('productValueTotal: $productValueTotal, ')
          ..write('cashInvested: $cashInvested, ')
          ..write('productInvested: $productInvested')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    investedAmount,
    durationMonths,
    profitPercentage,
    dailyEarnings,
    monthlyEarnings,
    contractType,
    investmentType,
    isActive,
    startDate,
    totalBought,
    totalSold,
    totalProfit,
    remainingBalance,
    productValueTotal,
    cashInvested,
    productInvested,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Investor &&
          other.id == this.id &&
          other.name == this.name &&
          other.investedAmount == this.investedAmount &&
          other.durationMonths == this.durationMonths &&
          other.profitPercentage == this.profitPercentage &&
          other.dailyEarnings == this.dailyEarnings &&
          other.monthlyEarnings == this.monthlyEarnings &&
          other.contractType == this.contractType &&
          other.investmentType == this.investmentType &&
          other.isActive == this.isActive &&
          other.startDate == this.startDate &&
          other.totalBought == this.totalBought &&
          other.totalSold == this.totalSold &&
          other.totalProfit == this.totalProfit &&
          other.remainingBalance == this.remainingBalance &&
          other.productValueTotal == this.productValueTotal &&
          other.cashInvested == this.cashInvested &&
          other.productInvested == this.productInvested);
}

class InvestorsCompanion extends UpdateCompanion<Investor> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> investedAmount;
  final Value<int> durationMonths;
  final Value<double> profitPercentage;
  final Value<double> dailyEarnings;
  final Value<double> monthlyEarnings;
  final Value<String> contractType;
  final Value<String> investmentType;
  final Value<bool> isActive;
  final Value<String> startDate;
  final Value<double> totalBought;
  final Value<double> totalSold;
  final Value<double> totalProfit;
  final Value<double> remainingBalance;
  final Value<double> productValueTotal;
  final Value<double> cashInvested;
  final Value<double> productInvested;
  final Value<int> rowid;
  const InvestorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.investedAmount = const Value.absent(),
    this.durationMonths = const Value.absent(),
    this.profitPercentage = const Value.absent(),
    this.dailyEarnings = const Value.absent(),
    this.monthlyEarnings = const Value.absent(),
    this.contractType = const Value.absent(),
    this.investmentType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.startDate = const Value.absent(),
    this.totalBought = const Value.absent(),
    this.totalSold = const Value.absent(),
    this.totalProfit = const Value.absent(),
    this.remainingBalance = const Value.absent(),
    this.productValueTotal = const Value.absent(),
    this.cashInvested = const Value.absent(),
    this.productInvested = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestorsCompanion.insert({
    required String id,
    required String name,
    this.investedAmount = const Value.absent(),
    this.durationMonths = const Value.absent(),
    this.profitPercentage = const Value.absent(),
    this.dailyEarnings = const Value.absent(),
    this.monthlyEarnings = const Value.absent(),
    this.contractType = const Value.absent(),
    this.investmentType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.startDate = const Value.absent(),
    this.totalBought = const Value.absent(),
    this.totalSold = const Value.absent(),
    this.totalProfit = const Value.absent(),
    this.remainingBalance = const Value.absent(),
    this.productValueTotal = const Value.absent(),
    this.cashInvested = const Value.absent(),
    this.productInvested = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Investor> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? investedAmount,
    Expression<int>? durationMonths,
    Expression<double>? profitPercentage,
    Expression<double>? dailyEarnings,
    Expression<double>? monthlyEarnings,
    Expression<String>? contractType,
    Expression<String>? investmentType,
    Expression<bool>? isActive,
    Expression<String>? startDate,
    Expression<double>? totalBought,
    Expression<double>? totalSold,
    Expression<double>? totalProfit,
    Expression<double>? remainingBalance,
    Expression<double>? productValueTotal,
    Expression<double>? cashInvested,
    Expression<double>? productInvested,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (investedAmount != null) 'invested_amount': investedAmount,
      if (durationMonths != null) 'duration_months': durationMonths,
      if (profitPercentage != null) 'profit_percentage': profitPercentage,
      if (dailyEarnings != null) 'daily_earnings': dailyEarnings,
      if (monthlyEarnings != null) 'monthly_earnings': monthlyEarnings,
      if (contractType != null) 'contract_type': contractType,
      if (investmentType != null) 'investment_type': investmentType,
      if (isActive != null) 'is_active': isActive,
      if (startDate != null) 'start_date': startDate,
      if (totalBought != null) 'total_bought': totalBought,
      if (totalSold != null) 'total_sold': totalSold,
      if (totalProfit != null) 'total_profit': totalProfit,
      if (remainingBalance != null) 'remaining_balance': remainingBalance,
      if (productValueTotal != null) 'product_value_total': productValueTotal,
      if (cashInvested != null) 'cash_invested': cashInvested,
      if (productInvested != null) 'product_invested': productInvested,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestorsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? investedAmount,
    Value<int>? durationMonths,
    Value<double>? profitPercentage,
    Value<double>? dailyEarnings,
    Value<double>? monthlyEarnings,
    Value<String>? contractType,
    Value<String>? investmentType,
    Value<bool>? isActive,
    Value<String>? startDate,
    Value<double>? totalBought,
    Value<double>? totalSold,
    Value<double>? totalProfit,
    Value<double>? remainingBalance,
    Value<double>? productValueTotal,
    Value<double>? cashInvested,
    Value<double>? productInvested,
    Value<int>? rowid,
  }) {
    return InvestorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      investedAmount: investedAmount ?? this.investedAmount,
      durationMonths: durationMonths ?? this.durationMonths,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      contractType: contractType ?? this.contractType,
      investmentType: investmentType ?? this.investmentType,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      totalBought: totalBought ?? this.totalBought,
      totalSold: totalSold ?? this.totalSold,
      totalProfit: totalProfit ?? this.totalProfit,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      productValueTotal: productValueTotal ?? this.productValueTotal,
      cashInvested: cashInvested ?? this.cashInvested,
      productInvested: productInvested ?? this.productInvested,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (investedAmount.present) {
      map['invested_amount'] = Variable<double>(investedAmount.value);
    }
    if (durationMonths.present) {
      map['duration_months'] = Variable<int>(durationMonths.value);
    }
    if (profitPercentage.present) {
      map['profit_percentage'] = Variable<double>(profitPercentage.value);
    }
    if (dailyEarnings.present) {
      map['daily_earnings'] = Variable<double>(dailyEarnings.value);
    }
    if (monthlyEarnings.present) {
      map['monthly_earnings'] = Variable<double>(monthlyEarnings.value);
    }
    if (contractType.present) {
      map['contract_type'] = Variable<String>(contractType.value);
    }
    if (investmentType.present) {
      map['investment_type'] = Variable<String>(investmentType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (totalBought.present) {
      map['total_bought'] = Variable<double>(totalBought.value);
    }
    if (totalSold.present) {
      map['total_sold'] = Variable<double>(totalSold.value);
    }
    if (totalProfit.present) {
      map['total_profit'] = Variable<double>(totalProfit.value);
    }
    if (remainingBalance.present) {
      map['remaining_balance'] = Variable<double>(remainingBalance.value);
    }
    if (productValueTotal.present) {
      map['product_value_total'] = Variable<double>(productValueTotal.value);
    }
    if (cashInvested.present) {
      map['cash_invested'] = Variable<double>(cashInvested.value);
    }
    if (productInvested.present) {
      map['product_invested'] = Variable<double>(productInvested.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('investedAmount: $investedAmount, ')
          ..write('durationMonths: $durationMonths, ')
          ..write('profitPercentage: $profitPercentage, ')
          ..write('dailyEarnings: $dailyEarnings, ')
          ..write('monthlyEarnings: $monthlyEarnings, ')
          ..write('contractType: $contractType, ')
          ..write('investmentType: $investmentType, ')
          ..write('isActive: $isActive, ')
          ..write('startDate: $startDate, ')
          ..write('totalBought: $totalBought, ')
          ..write('totalSold: $totalSold, ')
          ..write('totalProfit: $totalProfit, ')
          ..write('remainingBalance: $remainingBalance, ')
          ..write('productValueTotal: $productValueTotal, ')
          ..write('cashInvested: $cashInvested, ')
          ..write('productInvested: $productInvested, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RepaymentsTable extends Repayments
    with TableInfo<$RepaymentsTable, Repayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _investorIdMeta = const VerificationMeta(
    'investorId',
  );
  @override
  late final GeneratedColumn<String> investorId = GeneratedColumn<String>(
    'investor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, investorId, amount, date, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repayments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Repayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('investor_id')) {
      context.handle(
        _investorIdMeta,
        investorId.isAcceptableOrUnknown(data['investor_id']!, _investorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_investorIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Repayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Repayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      investorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investor_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $RepaymentsTable createAlias(String alias) {
    return $RepaymentsTable(attachedDatabase, alias);
  }
}

class Repayment extends DataClass implements Insertable<Repayment> {
  final String id;
  final String investorId;
  final double amount;
  final String date;
  final String notes;
  const Repayment({
    required this.id,
    required this.investorId,
    required this.amount,
    required this.date,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['investor_id'] = Variable<String>(investorId);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<String>(date);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  RepaymentsCompanion toCompanion(bool nullToAbsent) {
    return RepaymentsCompanion(
      id: Value(id),
      investorId: Value(investorId),
      amount: Value(amount),
      date: Value(date),
      notes: Value(notes),
    );
  }

  factory Repayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Repayment(
      id: serializer.fromJson<String>(json['id']),
      investorId: serializer.fromJson<String>(json['investorId']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'investorId': serializer.toJson<String>(investorId),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<String>(date),
      'notes': serializer.toJson<String>(notes),
    };
  }

  Repayment copyWith({
    String? id,
    String? investorId,
    double? amount,
    String? date,
    String? notes,
  }) => Repayment(
    id: id ?? this.id,
    investorId: investorId ?? this.investorId,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    notes: notes ?? this.notes,
  );
  Repayment copyWithCompanion(RepaymentsCompanion data) {
    return Repayment(
      id: data.id.present ? data.id.value : this.id,
      investorId: data.investorId.present
          ? data.investorId.value
          : this.investorId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Repayment(')
          ..write('id: $id, ')
          ..write('investorId: $investorId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, investorId, amount, date, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Repayment &&
          other.id == this.id &&
          other.investorId == this.investorId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.notes == this.notes);
}

class RepaymentsCompanion extends UpdateCompanion<Repayment> {
  final Value<String> id;
  final Value<String> investorId;
  final Value<double> amount;
  final Value<String> date;
  final Value<String> notes;
  final Value<int> rowid;
  const RepaymentsCompanion({
    this.id = const Value.absent(),
    this.investorId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RepaymentsCompanion.insert({
    required String id,
    required String investorId,
    required double amount,
    required String date,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       investorId = Value(investorId),
       amount = Value(amount),
       date = Value(date);
  static Insertable<Repayment> custom({
    Expression<String>? id,
    Expression<String>? investorId,
    Expression<double>? amount,
    Expression<String>? date,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (investorId != null) 'investor_id': investorId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RepaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? investorId,
    Value<double>? amount,
    Value<String>? date,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return RepaymentsCompanion(
      id: id ?? this.id,
      investorId: investorId ?? this.investorId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (investorId.present) {
      map['investor_id'] = Variable<String>(investorId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepaymentsCompanion(')
          ..write('id: $id, ')
          ..write('investorId: $investorId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FixedAssetsTable extends FixedAssets
    with TableInfo<$FixedAssetsTable, FixedAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FixedAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedValueMeta = const VerificationMeta(
    'estimatedValue',
  );
  @override
  late final GeneratedColumn<double> estimatedValue = GeneratedColumn<double>(
    'estimated_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    estimatedValue,
    purchaseDate,
    imagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fixed_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<FixedAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('estimated_value')) {
      context.handle(
        _estimatedValueMeta,
        estimatedValue.isAcceptableOrUnknown(
          data['estimated_value']!,
          _estimatedValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estimatedValueMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FixedAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FixedAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      estimatedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_value'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
    );
  }

  @override
  $FixedAssetsTable createAlias(String alias) {
    return $FixedAssetsTable(attachedDatabase, alias);
  }
}

class FixedAsset extends DataClass implements Insertable<FixedAsset> {
  final String id;
  final String name;
  final double estimatedValue;
  final String purchaseDate;
  final String imagePath;
  const FixedAsset({
    required this.id,
    required this.name,
    required this.estimatedValue,
    required this.purchaseDate,
    required this.imagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['estimated_value'] = Variable<double>(estimatedValue);
    map['purchase_date'] = Variable<String>(purchaseDate);
    map['image_path'] = Variable<String>(imagePath);
    return map;
  }

  FixedAssetsCompanion toCompanion(bool nullToAbsent) {
    return FixedAssetsCompanion(
      id: Value(id),
      name: Value(name),
      estimatedValue: Value(estimatedValue),
      purchaseDate: Value(purchaseDate),
      imagePath: Value(imagePath),
    );
  }

  factory FixedAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FixedAsset(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      estimatedValue: serializer.fromJson<double>(json['estimatedValue']),
      purchaseDate: serializer.fromJson<String>(json['purchaseDate']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'estimatedValue': serializer.toJson<double>(estimatedValue),
      'purchaseDate': serializer.toJson<String>(purchaseDate),
      'imagePath': serializer.toJson<String>(imagePath),
    };
  }

  FixedAsset copyWith({
    String? id,
    String? name,
    double? estimatedValue,
    String? purchaseDate,
    String? imagePath,
  }) => FixedAsset(
    id: id ?? this.id,
    name: name ?? this.name,
    estimatedValue: estimatedValue ?? this.estimatedValue,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    imagePath: imagePath ?? this.imagePath,
  );
  FixedAsset copyWithCompanion(FixedAssetsCompanion data) {
    return FixedAsset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      estimatedValue: data.estimatedValue.present
          ? data.estimatedValue.value
          : this.estimatedValue,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FixedAsset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('estimatedValue: $estimatedValue, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, estimatedValue, purchaseDate, imagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedAsset &&
          other.id == this.id &&
          other.name == this.name &&
          other.estimatedValue == this.estimatedValue &&
          other.purchaseDate == this.purchaseDate &&
          other.imagePath == this.imagePath);
}

class FixedAssetsCompanion extends UpdateCompanion<FixedAsset> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> estimatedValue;
  final Value<String> purchaseDate;
  final Value<String> imagePath;
  final Value<int> rowid;
  const FixedAssetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.estimatedValue = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FixedAssetsCompanion.insert({
    required String id,
    required String name,
    required double estimatedValue,
    required String purchaseDate,
    this.imagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       estimatedValue = Value(estimatedValue),
       purchaseDate = Value(purchaseDate);
  static Insertable<FixedAsset> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? estimatedValue,
    Expression<String>? purchaseDate,
    Expression<String>? imagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (estimatedValue != null) 'estimated_value': estimatedValue,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (imagePath != null) 'image_path': imagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FixedAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? estimatedValue,
    Value<String>? purchaseDate,
    Value<String>? imagePath,
    Value<int>? rowid,
  }) {
    return FixedAssetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      imagePath: imagePath ?? this.imagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (estimatedValue.present) {
      map['estimated_value'] = Variable<double>(estimatedValue.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FixedAssetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('estimatedValue: $estimatedValue, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('imagePath: $imagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickCapturesTable extends QuickCaptures
    with TableInfo<$QuickCapturesTable, QuickCapture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickCapturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    note,
    imagePath,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickCapture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickCapture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickCapture(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $QuickCapturesTable createAlias(String alias) {
    return $QuickCapturesTable(attachedDatabase, alias);
  }
}

class QuickCapture extends DataClass implements Insertable<QuickCapture> {
  final String id;
  final String timestamp;
  final String note;
  final String imagePath;
  final String source;
  const QuickCapture({
    required this.id,
    required this.timestamp,
    required this.note,
    required this.imagePath,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['timestamp'] = Variable<String>(timestamp);
    map['note'] = Variable<String>(note);
    map['image_path'] = Variable<String>(imagePath);
    map['source'] = Variable<String>(source);
    return map;
  }

  QuickCapturesCompanion toCompanion(bool nullToAbsent) {
    return QuickCapturesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      note: Value(note),
      imagePath: Value(imagePath),
      source: Value(source),
    );
  }

  factory QuickCapture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickCapture(
      id: serializer.fromJson<String>(json['id']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      note: serializer.fromJson<String>(json['note']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timestamp': serializer.toJson<String>(timestamp),
      'note': serializer.toJson<String>(note),
      'imagePath': serializer.toJson<String>(imagePath),
      'source': serializer.toJson<String>(source),
    };
  }

  QuickCapture copyWith({
    String? id,
    String? timestamp,
    String? note,
    String? imagePath,
    String? source,
  }) => QuickCapture(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    note: note ?? this.note,
    imagePath: imagePath ?? this.imagePath,
    source: source ?? this.source,
  );
  QuickCapture copyWithCompanion(QuickCapturesCompanion data) {
    return QuickCapture(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      note: data.note.present ? data.note.value : this.note,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickCapture(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, note, imagePath, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickCapture &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.note == this.note &&
          other.imagePath == this.imagePath &&
          other.source == this.source);
}

class QuickCapturesCompanion extends UpdateCompanion<QuickCapture> {
  final Value<String> id;
  final Value<String> timestamp;
  final Value<String> note;
  final Value<String> imagePath;
  final Value<String> source;
  final Value<int> rowid;
  const QuickCapturesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickCapturesCompanion.insert({
    required String id,
    required String timestamp,
    required String note,
    this.imagePath = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       note = Value(note);
  static Insertable<QuickCapture> custom({
    Expression<String>? id,
    Expression<String>? timestamp,
    Expression<String>? note,
    Expression<String>? imagePath,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (note != null) 'note': note,
      if (imagePath != null) 'image_path': imagePath,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickCapturesCompanion copyWith({
    Value<String>? id,
    Value<String>? timestamp,
    Value<String>? note,
    Value<String>? imagePath,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return QuickCapturesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickCapturesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RentBooksTable extends RentBooks
    with TableInfo<$RentBooksTable, RentBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _copiesMeta = const VerificationMeta('copies');
  @override
  late final GeneratedColumn<int> copies = GeneratedColumn<int>(
    'copies',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, pageCount, copies];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rent_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentBook> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('copies')) {
      context.handle(
        _copiesMeta,
        copies.isAcceptableOrUnknown(data['copies']!, _copiesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentBook(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      copies: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}copies'],
      )!,
    );
  }

  @override
  $RentBooksTable createAlias(String alias) {
    return $RentBooksTable(attachedDatabase, alias);
  }
}

class RentBook extends DataClass implements Insertable<RentBook> {
  final String id;
  final String name;
  final int pageCount;
  final int copies;
  const RentBook({
    required this.id,
    required this.name,
    required this.pageCount,
    required this.copies,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['page_count'] = Variable<int>(pageCount);
    map['copies'] = Variable<int>(copies);
    return map;
  }

  RentBooksCompanion toCompanion(bool nullToAbsent) {
    return RentBooksCompanion(
      id: Value(id),
      name: Value(name),
      pageCount: Value(pageCount),
      copies: Value(copies),
    );
  }

  factory RentBook.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentBook(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      copies: serializer.fromJson<int>(json['copies']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'pageCount': serializer.toJson<int>(pageCount),
      'copies': serializer.toJson<int>(copies),
    };
  }

  RentBook copyWith({String? id, String? name, int? pageCount, int? copies}) =>
      RentBook(
        id: id ?? this.id,
        name: name ?? this.name,
        pageCount: pageCount ?? this.pageCount,
        copies: copies ?? this.copies,
      );
  RentBook copyWithCompanion(RentBooksCompanion data) {
    return RentBook(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      copies: data.copies.present ? data.copies.value : this.copies,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentBook(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pageCount: $pageCount, ')
          ..write('copies: $copies')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, pageCount, copies);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentBook &&
          other.id == this.id &&
          other.name == this.name &&
          other.pageCount == this.pageCount &&
          other.copies == this.copies);
}

class RentBooksCompanion extends UpdateCompanion<RentBook> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> pageCount;
  final Value<int> copies;
  final Value<int> rowid;
  const RentBooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.copies = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentBooksCompanion.insert({
    required String id,
    required String name,
    this.pageCount = const Value.absent(),
    this.copies = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<RentBook> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? pageCount,
    Expression<int>? copies,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pageCount != null) 'page_count': pageCount,
      if (copies != null) 'copies': copies,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentBooksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? pageCount,
    Value<int>? copies,
    Value<int>? rowid,
  }) {
    return RentBooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      pageCount: pageCount ?? this.pageCount,
      copies: copies ?? this.copies,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (copies.present) {
      map['copies'] = Variable<int>(copies.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentBooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pageCount: $pageCount, ')
          ..write('copies: $copies, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookRentalsTable extends BookRentals
    with TableInfo<$BookRentalsTable, BookRental> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookRentalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<String> dateTaken = GeneratedColumn<String>(
    'date_taken',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedReturnMeta = const VerificationMeta(
    'expectedReturn',
  );
  @override
  late final GeneratedColumn<String> expectedReturn = GeneratedColumn<String>(
    'expected_return',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateReturnedMeta = const VerificationMeta(
    'dateReturned',
  );
  @override
  late final GeneratedColumn<String> dateReturned = GeneratedColumn<String>(
    'date_returned',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
    'is_paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookName,
    pageCount,
    customerName,
    dateTaken,
    expectedReturn,
    dateReturned,
    cost,
    isPaid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_rentals';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRental> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    } else if (isInserting) {
      context.missing(_dateTakenMeta);
    }
    if (data.containsKey('expected_return')) {
      context.handle(
        _expectedReturnMeta,
        expectedReturn.isAcceptableOrUnknown(
          data['expected_return']!,
          _expectedReturnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedReturnMeta);
    }
    if (data.containsKey('date_returned')) {
      context.handle(
        _dateReturnedMeta,
        dateReturned.isAcceptableOrUnknown(
          data['date_returned']!,
          _dateReturnedMeta,
        ),
      );
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('is_paid')) {
      context.handle(
        _isPaidMeta,
        isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRental map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRental(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_taken'],
      )!,
      expectedReturn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_return'],
      )!,
      dateReturned: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_returned'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
      isPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paid'],
      )!,
    );
  }

  @override
  $BookRentalsTable createAlias(String alias) {
    return $BookRentalsTable(attachedDatabase, alias);
  }
}

class BookRental extends DataClass implements Insertable<BookRental> {
  final String id;
  final String bookName;
  final int pageCount;
  final String customerName;
  final String dateTaken;
  final String expectedReturn;
  final String dateReturned;
  final double cost;
  final bool isPaid;
  const BookRental({
    required this.id,
    required this.bookName,
    required this.pageCount,
    required this.customerName,
    required this.dateTaken,
    required this.expectedReturn,
    required this.dateReturned,
    required this.cost,
    required this.isPaid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_name'] = Variable<String>(bookName);
    map['page_count'] = Variable<int>(pageCount);
    map['customer_name'] = Variable<String>(customerName);
    map['date_taken'] = Variable<String>(dateTaken);
    map['expected_return'] = Variable<String>(expectedReturn);
    map['date_returned'] = Variable<String>(dateReturned);
    map['cost'] = Variable<double>(cost);
    map['is_paid'] = Variable<bool>(isPaid);
    return map;
  }

  BookRentalsCompanion toCompanion(bool nullToAbsent) {
    return BookRentalsCompanion(
      id: Value(id),
      bookName: Value(bookName),
      pageCount: Value(pageCount),
      customerName: Value(customerName),
      dateTaken: Value(dateTaken),
      expectedReturn: Value(expectedReturn),
      dateReturned: Value(dateReturned),
      cost: Value(cost),
      isPaid: Value(isPaid),
    );
  }

  factory BookRental.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRental(
      id: serializer.fromJson<String>(json['id']),
      bookName: serializer.fromJson<String>(json['bookName']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      customerName: serializer.fromJson<String>(json['customerName']),
      dateTaken: serializer.fromJson<String>(json['dateTaken']),
      expectedReturn: serializer.fromJson<String>(json['expectedReturn']),
      dateReturned: serializer.fromJson<String>(json['dateReturned']),
      cost: serializer.fromJson<double>(json['cost']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookName': serializer.toJson<String>(bookName),
      'pageCount': serializer.toJson<int>(pageCount),
      'customerName': serializer.toJson<String>(customerName),
      'dateTaken': serializer.toJson<String>(dateTaken),
      'expectedReturn': serializer.toJson<String>(expectedReturn),
      'dateReturned': serializer.toJson<String>(dateReturned),
      'cost': serializer.toJson<double>(cost),
      'isPaid': serializer.toJson<bool>(isPaid),
    };
  }

  BookRental copyWith({
    String? id,
    String? bookName,
    int? pageCount,
    String? customerName,
    String? dateTaken,
    String? expectedReturn,
    String? dateReturned,
    double? cost,
    bool? isPaid,
  }) => BookRental(
    id: id ?? this.id,
    bookName: bookName ?? this.bookName,
    pageCount: pageCount ?? this.pageCount,
    customerName: customerName ?? this.customerName,
    dateTaken: dateTaken ?? this.dateTaken,
    expectedReturn: expectedReturn ?? this.expectedReturn,
    dateReturned: dateReturned ?? this.dateReturned,
    cost: cost ?? this.cost,
    isPaid: isPaid ?? this.isPaid,
  );
  BookRental copyWithCompanion(BookRentalsCompanion data) {
    return BookRental(
      id: data.id.present ? data.id.value : this.id,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
      expectedReturn: data.expectedReturn.present
          ? data.expectedReturn.value
          : this.expectedReturn,
      dateReturned: data.dateReturned.present
          ? data.dateReturned.value
          : this.dateReturned,
      cost: data.cost.present ? data.cost.value : this.cost,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRental(')
          ..write('id: $id, ')
          ..write('bookName: $bookName, ')
          ..write('pageCount: $pageCount, ')
          ..write('customerName: $customerName, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('expectedReturn: $expectedReturn, ')
          ..write('dateReturned: $dateReturned, ')
          ..write('cost: $cost, ')
          ..write('isPaid: $isPaid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookName,
    pageCount,
    customerName,
    dateTaken,
    expectedReturn,
    dateReturned,
    cost,
    isPaid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRental &&
          other.id == this.id &&
          other.bookName == this.bookName &&
          other.pageCount == this.pageCount &&
          other.customerName == this.customerName &&
          other.dateTaken == this.dateTaken &&
          other.expectedReturn == this.expectedReturn &&
          other.dateReturned == this.dateReturned &&
          other.cost == this.cost &&
          other.isPaid == this.isPaid);
}

class BookRentalsCompanion extends UpdateCompanion<BookRental> {
  final Value<String> id;
  final Value<String> bookName;
  final Value<int> pageCount;
  final Value<String> customerName;
  final Value<String> dateTaken;
  final Value<String> expectedReturn;
  final Value<String> dateReturned;
  final Value<double> cost;
  final Value<bool> isPaid;
  final Value<int> rowid;
  const BookRentalsCompanion({
    this.id = const Value.absent(),
    this.bookName = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.customerName = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.expectedReturn = const Value.absent(),
    this.dateReturned = const Value.absent(),
    this.cost = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookRentalsCompanion.insert({
    required String id,
    required String bookName,
    this.pageCount = const Value.absent(),
    required String customerName,
    required String dateTaken,
    required String expectedReturn,
    this.dateReturned = const Value.absent(),
    this.cost = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookName = Value(bookName),
       customerName = Value(customerName),
       dateTaken = Value(dateTaken),
       expectedReturn = Value(expectedReturn);
  static Insertable<BookRental> custom({
    Expression<String>? id,
    Expression<String>? bookName,
    Expression<int>? pageCount,
    Expression<String>? customerName,
    Expression<String>? dateTaken,
    Expression<String>? expectedReturn,
    Expression<String>? dateReturned,
    Expression<double>? cost,
    Expression<bool>? isPaid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookName != null) 'book_name': bookName,
      if (pageCount != null) 'page_count': pageCount,
      if (customerName != null) 'customer_name': customerName,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (expectedReturn != null) 'expected_return': expectedReturn,
      if (dateReturned != null) 'date_returned': dateReturned,
      if (cost != null) 'cost': cost,
      if (isPaid != null) 'is_paid': isPaid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookRentalsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookName,
    Value<int>? pageCount,
    Value<String>? customerName,
    Value<String>? dateTaken,
    Value<String>? expectedReturn,
    Value<String>? dateReturned,
    Value<double>? cost,
    Value<bool>? isPaid,
    Value<int>? rowid,
  }) {
    return BookRentalsCompanion(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      pageCount: pageCount ?? this.pageCount,
      customerName: customerName ?? this.customerName,
      dateTaken: dateTaken ?? this.dateTaken,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      dateReturned: dateReturned ?? this.dateReturned,
      cost: cost ?? this.cost,
      isPaid: isPaid ?? this.isPaid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<String>(dateTaken.value);
    }
    if (expectedReturn.present) {
      map['expected_return'] = Variable<String>(expectedReturn.value);
    }
    if (dateReturned.present) {
      map['date_returned'] = Variable<String>(dateReturned.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookRentalsCompanion(')
          ..write('id: $id, ')
          ..write('bookName: $bookName, ')
          ..write('pageCount: $pageCount, ')
          ..write('customerName: $customerName, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('expectedReturn: $expectedReturn, ')
          ..write('dateReturned: $dateReturned, ')
          ..write('cost: $cost, ')
          ..write('isPaid: $isPaid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  const Category({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(id: Value(id), name: Value(name));
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Category copyWith({int? id, String? name}) =>
      Category(id: id ?? this.id, name: name ?? this.name);
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category && other.id == this.id && other.name == this.name);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  CategoriesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return CategoriesCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $CustomerTypesTable extends CustomerTypes
    with TableInfo<$CustomerTypesTable, CustomerType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconIndexMeta = const VerificationMeta(
    'iconIndex',
  );
  @override
  late final GeneratedColumn<int> iconIndex = GeneratedColumn<int>(
    'icon_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, iconIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('icon_index')) {
      context.handle(
        _iconIndexMeta,
        iconIndex.isAcceptableOrUnknown(data['icon_index']!, _iconIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      iconIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_index'],
      )!,
    );
  }

  @override
  $CustomerTypesTable createAlias(String alias) {
    return $CustomerTypesTable(attachedDatabase, alias);
  }
}

class CustomerType extends DataClass implements Insertable<CustomerType> {
  final String id;
  final String label;
  final int iconIndex;
  const CustomerType({
    required this.id,
    required this.label,
    required this.iconIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['icon_index'] = Variable<int>(iconIndex);
    return map;
  }

  CustomerTypesCompanion toCompanion(bool nullToAbsent) {
    return CustomerTypesCompanion(
      id: Value(id),
      label: Value(label),
      iconIndex: Value(iconIndex),
    );
  }

  factory CustomerType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerType(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      iconIndex: serializer.fromJson<int>(json['iconIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'iconIndex': serializer.toJson<int>(iconIndex),
    };
  }

  CustomerType copyWith({String? id, String? label, int? iconIndex}) =>
      CustomerType(
        id: id ?? this.id,
        label: label ?? this.label,
        iconIndex: iconIndex ?? this.iconIndex,
      );
  CustomerType copyWithCompanion(CustomerTypesCompanion data) {
    return CustomerType(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      iconIndex: data.iconIndex.present ? data.iconIndex.value : this.iconIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerType(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('iconIndex: $iconIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, iconIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerType &&
          other.id == this.id &&
          other.label == this.label &&
          other.iconIndex == this.iconIndex);
}

class CustomerTypesCompanion extends UpdateCompanion<CustomerType> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> iconIndex;
  final Value<int> rowid;
  const CustomerTypesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.iconIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerTypesCompanion.insert({
    required String id,
    required String label,
    this.iconIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label);
  static Insertable<CustomerType> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? iconIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (iconIndex != null) 'icon_index': iconIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? iconIndex,
    Value<int>? rowid,
  }) {
    return CustomerTypesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      iconIndex: iconIndex ?? this.iconIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (iconIndex.present) {
      map['icon_index'] = Variable<int>(iconIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerTypesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('iconIndex: $iconIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $CustomerPurchasesTable customerPurchases =
      $CustomerPurchasesTable(this);
  late final $CustomerOrdersTable customerOrders = $CustomerOrdersTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $PurchaseItemsTable purchaseItems = $PurchaseItemsTable(this);
  late final $TransportCostsTable transportCosts = $TransportCostsTable(this);
  late final $OtherCostsTable otherCosts = $OtherCostsTable(this);
  late final $InvestorsTable investors = $InvestorsTable(this);
  late final $RepaymentsTable repayments = $RepaymentsTable(this);
  late final $FixedAssetsTable fixedAssets = $FixedAssetsTable(this);
  late final $QuickCapturesTable quickCaptures = $QuickCapturesTable(this);
  late final $RentBooksTable rentBooks = $RentBooksTable(this);
  late final $BookRentalsTable bookRentals = $BookRentalsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $CustomerTypesTable customerTypes = $CustomerTypesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final ProductDao productDao = ProductDao(this as AppDatabase);
  late final SaleDao saleDao = SaleDao(this as AppDatabase);
  late final CustomerDao customerDao = CustomerDao(this as AppDatabase);
  late final ExpenseDao expenseDao = ExpenseDao(this as AppDatabase);
  late final PurchaseDao purchaseDao = PurchaseDao(this as AppDatabase);
  late final InvestorDao investorDao = InvestorDao(this as AppDatabase);
  late final AssetDao assetDao = AssetDao(this as AppDatabase);
  late final RentalDao rentalDao = RentalDao(this as AppDatabase);
  late final QuickCaptureDao quickCaptureDao = QuickCaptureDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    sales,
    customers,
    ledgerEntries,
    customerPurchases,
    customerOrders,
    expenses,
    purchases,
    purchaseItems,
    transportCosts,
    otherCosts,
    investors,
    repayments,
    fixedAssets,
    quickCaptures,
    rentBooks,
    bookRentals,
    categories,
    customerTypes,
    appSettings,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      Value<String> category,
      Value<String> investor,
      required String name,
      Value<double> buyQty,
      Value<String> buyUnit,
      Value<double> buyPrice,
      Value<String> sellUnit,
      Value<double> sellPrice,
      Value<double> qty,
      Value<double> buyConversionFactor,
      Value<double> sellConversionFactor,
      required String date,
      Value<String> imagePath,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String> investor,
      Value<String> name,
      Value<double> buyQty,
      Value<String> buyUnit,
      Value<double> buyPrice,
      Value<String> sellUnit,
      Value<double> sellPrice,
      Value<double> qty,
      Value<double> buyConversionFactor,
      Value<double> sellConversionFactor,
      Value<String> date,
      Value<String> imagePath,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get investor => $composableBuilder(
    column: $table.investor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyQty => $composableBuilder(
    column: $table.buyQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyUnit => $composableBuilder(
    column: $table.buyUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellUnit => $composableBuilder(
    column: $table.sellUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get buyConversionFactor => $composableBuilder(
    column: $table.buyConversionFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sellConversionFactor => $composableBuilder(
    column: $table.sellConversionFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get investor => $composableBuilder(
    column: $table.investor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyQty => $composableBuilder(
    column: $table.buyQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyUnit => $composableBuilder(
    column: $table.buyUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyPrice => $composableBuilder(
    column: $table.buyPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellUnit => $composableBuilder(
    column: $table.sellUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get buyConversionFactor => $composableBuilder(
    column: $table.buyConversionFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sellConversionFactor => $composableBuilder(
    column: $table.sellConversionFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get investor =>
      $composableBuilder(column: $table.investor, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get buyQty =>
      $composableBuilder(column: $table.buyQty, builder: (column) => column);

  GeneratedColumn<String> get buyUnit =>
      $composableBuilder(column: $table.buyUnit, builder: (column) => column);

  GeneratedColumn<double> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => column);

  GeneratedColumn<String> get sellUnit =>
      $composableBuilder(column: $table.sellUnit, builder: (column) => column);

  GeneratedColumn<double> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get buyConversionFactor => $composableBuilder(
    column: $table.buyConversionFactor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sellConversionFactor => $composableBuilder(
    column: $table.sellConversionFactor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> investor = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> buyQty = const Value.absent(),
                Value<String> buyUnit = const Value.absent(),
                Value<double> buyPrice = const Value.absent(),
                Value<String> sellUnit = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<double> qty = const Value.absent(),
                Value<double> buyConversionFactor = const Value.absent(),
                Value<double> sellConversionFactor = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                category: category,
                investor: investor,
                name: name,
                buyQty: buyQty,
                buyUnit: buyUnit,
                buyPrice: buyPrice,
                sellUnit: sellUnit,
                sellPrice: sellPrice,
                qty: qty,
                buyConversionFactor: buyConversionFactor,
                sellConversionFactor: sellConversionFactor,
                date: date,
                imagePath: imagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> category = const Value.absent(),
                Value<String> investor = const Value.absent(),
                required String name,
                Value<double> buyQty = const Value.absent(),
                Value<String> buyUnit = const Value.absent(),
                Value<double> buyPrice = const Value.absent(),
                Value<String> sellUnit = const Value.absent(),
                Value<double> sellPrice = const Value.absent(),
                Value<double> qty = const Value.absent(),
                Value<double> buyConversionFactor = const Value.absent(),
                Value<double> sellConversionFactor = const Value.absent(),
                required String date,
                Value<String> imagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                category: category,
                investor: investor,
                name: name,
                buyQty: buyQty,
                buyUnit: buyUnit,
                buyPrice: buyPrice,
                sellUnit: sellUnit,
                sellPrice: sellPrice,
                qty: qty,
                buyConversionFactor: buyConversionFactor,
                sellConversionFactor: sellConversionFactor,
                date: date,
                imagePath: imagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      required String id,
      required String date,
      required String productName,
      required double amount,
      Value<double> profit,
      Value<String> type,
      Value<int> rowid,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> productName,
      Value<double> amount,
      Value<double> profit,
      Value<String> type,
      Value<int> rowid,
    });

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profit => $composableBuilder(
    column: $table.profit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get profit =>
      $composableBuilder(column: $table.profit, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, BaseReferences<_$AppDatabase, $SalesTable, Sale>),
          Sale,
          PrefetchHooks Function()
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> profit = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                date: date,
                productName: productName,
                amount: amount,
                profit: profit,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String productName,
                required double amount,
                Value<double> profit = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                date: date,
                productName: productName,
                amount: amount,
                profit: profit,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, BaseReferences<_$AppDatabase, $SalesTable, Sale>),
      Sale,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      required String name,
      Value<String> phone,
      Value<String> whatsapp,
      Value<String> imagePath,
      Value<String> note,
      Value<String> address,
      Value<String> type,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> phone,
      Value<String> whatsapp,
      Value<String> imagePath,
      Value<String> note,
      Value<String> address,
      Value<String> type,
      Value<int> rowid,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get whatsapp =>
      $composableBuilder(column: $table.whatsapp, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> whatsapp = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                name: name,
                phone: phone,
                whatsapp: whatsapp,
                imagePath: imagePath,
                note: note,
                address: address,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> phone = const Value.absent(),
                Value<String> whatsapp = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                whatsapp: whatsapp,
                imagePath: imagePath,
                note: note,
                address: address,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      required String customerId,
      required String date,
      required double amount,
      required String type,
      Value<String> itemName,
      Value<String> imagePath,
      Value<String> note,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      Value<String> customerId,
      Value<String> date,
      Value<double> amount,
      Value<String> type,
      Value<String> itemName,
      Value<String> imagePath,
      Value<String> note,
    });

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (
            LedgerEntry,
            BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>,
          ),
          LedgerEntry,
          PrefetchHooks Function()
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                customerId: customerId,
                date: date,
                amount: amount,
                type: type,
                itemName: itemName,
                imagePath: imagePath,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String customerId,
                required String date,
                required double amount,
                required String type,
                Value<String> itemName = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                customerId: customerId,
                date: date,
                amount: amount,
                type: type,
                itemName: itemName,
                imagePath: imagePath,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (
        LedgerEntry,
        BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>,
      ),
      LedgerEntry,
      PrefetchHooks Function()
    >;
typedef $$CustomerPurchasesTableCreateCompanionBuilder =
    CustomerPurchasesCompanion Function({
      required String id,
      required String customerId,
      required String productName,
      required double price,
      required String date,
      Value<int> rowid,
    });
typedef $$CustomerPurchasesTableUpdateCompanionBuilder =
    CustomerPurchasesCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String> productName,
      Value<double> price,
      Value<String> date,
      Value<int> rowid,
    });

class $$CustomerPurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerPurchasesTable> {
  $$CustomerPurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerPurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerPurchasesTable> {
  $$CustomerPurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerPurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerPurchasesTable> {
  $$CustomerPurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$CustomerPurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerPurchasesTable,
          CustomerPurchase,
          $$CustomerPurchasesTableFilterComposer,
          $$CustomerPurchasesTableOrderingComposer,
          $$CustomerPurchasesTableAnnotationComposer,
          $$CustomerPurchasesTableCreateCompanionBuilder,
          $$CustomerPurchasesTableUpdateCompanionBuilder,
          (
            CustomerPurchase,
            BaseReferences<
              _$AppDatabase,
              $CustomerPurchasesTable,
              CustomerPurchase
            >,
          ),
          CustomerPurchase,
          PrefetchHooks Function()
        > {
  $$CustomerPurchasesTableTableManager(
    _$AppDatabase db,
    $CustomerPurchasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerPurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerPurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomerPurchasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerPurchasesCompanion(
                id: id,
                customerId: customerId,
                productName: productName,
                price: price,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String productName,
                required double price,
                required String date,
                Value<int> rowid = const Value.absent(),
              }) => CustomerPurchasesCompanion.insert(
                id: id,
                customerId: customerId,
                productName: productName,
                price: price,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerPurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerPurchasesTable,
      CustomerPurchase,
      $$CustomerPurchasesTableFilterComposer,
      $$CustomerPurchasesTableOrderingComposer,
      $$CustomerPurchasesTableAnnotationComposer,
      $$CustomerPurchasesTableCreateCompanionBuilder,
      $$CustomerPurchasesTableUpdateCompanionBuilder,
      (
        CustomerPurchase,
        BaseReferences<
          _$AppDatabase,
          $CustomerPurchasesTable,
          CustomerPurchase
        >,
      ),
      CustomerPurchase,
      PrefetchHooks Function()
    >;
typedef $$CustomerOrdersTableCreateCompanionBuilder =
    CustomerOrdersCompanion Function({
      required String id,
      required String customerId,
      required String description,
      required String dateGiven,
      required String dateNeeded,
      Value<String> status,
      Value<String> dateTaken,
      Value<int> rowid,
    });
typedef $$CustomerOrdersTableUpdateCompanionBuilder =
    CustomerOrdersCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String> description,
      Value<String> dateGiven,
      Value<String> dateNeeded,
      Value<String> status,
      Value<String> dateTaken,
      Value<int> rowid,
    });

class $$CustomerOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerOrdersTable> {
  $$CustomerOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateGiven => $composableBuilder(
    column: $table.dateGiven,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateNeeded => $composableBuilder(
    column: $table.dateNeeded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerOrdersTable> {
  $$CustomerOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateGiven => $composableBuilder(
    column: $table.dateGiven,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateNeeded => $composableBuilder(
    column: $table.dateNeeded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerOrdersTable> {
  $$CustomerOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateGiven =>
      $composableBuilder(column: $table.dateGiven, builder: (column) => column);

  GeneratedColumn<String> get dateNeeded => $composableBuilder(
    column: $table.dateNeeded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);
}

class $$CustomerOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerOrdersTable,
          CustomerOrder,
          $$CustomerOrdersTableFilterComposer,
          $$CustomerOrdersTableOrderingComposer,
          $$CustomerOrdersTableAnnotationComposer,
          $$CustomerOrdersTableCreateCompanionBuilder,
          $$CustomerOrdersTableUpdateCompanionBuilder,
          (
            CustomerOrder,
            BaseReferences<_$AppDatabase, $CustomerOrdersTable, CustomerOrder>,
          ),
          CustomerOrder,
          PrefetchHooks Function()
        > {
  $$CustomerOrdersTableTableManager(
    _$AppDatabase db,
    $CustomerOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomerOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> dateGiven = const Value.absent(),
                Value<String> dateNeeded = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> dateTaken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerOrdersCompanion(
                id: id,
                customerId: customerId,
                description: description,
                dateGiven: dateGiven,
                dateNeeded: dateNeeded,
                status: status,
                dateTaken: dateTaken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String description,
                required String dateGiven,
                required String dateNeeded,
                Value<String> status = const Value.absent(),
                Value<String> dateTaken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerOrdersCompanion.insert(
                id: id,
                customerId: customerId,
                description: description,
                dateGiven: dateGiven,
                dateNeeded: dateNeeded,
                status: status,
                dateTaken: dateTaken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerOrdersTable,
      CustomerOrder,
      $$CustomerOrdersTableFilterComposer,
      $$CustomerOrdersTableOrderingComposer,
      $$CustomerOrdersTableAnnotationComposer,
      $$CustomerOrdersTableCreateCompanionBuilder,
      $$CustomerOrdersTableUpdateCompanionBuilder,
      (
        CustomerOrder,
        BaseReferences<_$AppDatabase, $CustomerOrdersTable, CustomerOrder>,
      ),
      CustomerOrder,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      Value<String> type,
      required String title,
      required double amount,
      required String date,
      Value<String> billPath,
      Value<int?> dueDay,
      Value<String> note,
      Value<String> vendor,
      Value<String> paymentMethod,
      Value<bool> isPaid,
      Value<String> recurringType,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<double> amount,
      Value<String> date,
      Value<String> billPath,
      Value<int?> dueDay,
      Value<String> note,
      Value<String> vendor,
      Value<String> paymentMethod,
      Value<bool> isPaid,
      Value<String> recurringType,
      Value<int> rowid,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billPath => $composableBuilder(
    column: $table.billPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringType => $composableBuilder(
    column: $table.recurringType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billPath => $composableBuilder(
    column: $table.billPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringType => $composableBuilder(
    column: $table.recurringType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get billPath =>
      $composableBuilder(column: $table.billPath, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);

  GeneratedColumn<String> get recurringType => $composableBuilder(
    column: $table.recurringType,
    builder: (column) => column,
  );
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
          Expense,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> billPath = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> vendor = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
                Value<String> recurringType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                type: type,
                title: title,
                amount: amount,
                date: date,
                billPath: billPath,
                dueDay: dueDay,
                note: note,
                vendor: vendor,
                paymentMethod: paymentMethod,
                isPaid: isPaid,
                recurringType: recurringType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> type = const Value.absent(),
                required String title,
                required double amount,
                required String date,
                Value<String> billPath = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> vendor = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
                Value<String> recurringType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                type: type,
                title: title,
                amount: amount,
                date: date,
                billPath: billPath,
                dueDay: dueDay,
                note: note,
                vendor: vendor,
                paymentMethod: paymentMethod,
                isPaid: isPaid,
                recurringType: recurringType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
      Expense,
      PrefetchHooks Function()
    >;
typedef $$PurchasesTableCreateCompanionBuilder =
    PurchasesCompanion Function({
      required String id,
      required String date,
      Value<String> source,
      Value<double> cashTaken,
      Value<String> investorId,
      Value<String> notes,
      Value<String> memoPhotoPath,
      Value<double> returnedCash,
      Value<int> rowid,
    });
typedef $$PurchasesTableUpdateCompanionBuilder =
    PurchasesCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> source,
      Value<double> cashTaken,
      Value<String> investorId,
      Value<String> notes,
      Value<String> memoPhotoPath,
      Value<double> returnedCash,
      Value<int> rowid,
    });

class $$PurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashTaken => $composableBuilder(
    column: $table.cashTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get investorId => $composableBuilder(
    column: $table.investorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoPhotoPath => $composableBuilder(
    column: $table.memoPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get returnedCash => $composableBuilder(
    column: $table.returnedCash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashTaken => $composableBuilder(
    column: $table.cashTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get investorId => $composableBuilder(
    column: $table.investorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoPhotoPath => $composableBuilder(
    column: $table.memoPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get returnedCash => $composableBuilder(
    column: $table.returnedCash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get cashTaken =>
      $composableBuilder(column: $table.cashTaken, builder: (column) => column);

  GeneratedColumn<String> get investorId => $composableBuilder(
    column: $table.investorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get memoPhotoPath => $composableBuilder(
    column: $table.memoPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get returnedCash => $composableBuilder(
    column: $table.returnedCash,
    builder: (column) => column,
  );
}

class $$PurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchasesTable,
          Purchase,
          $$PurchasesTableFilterComposer,
          $$PurchasesTableOrderingComposer,
          $$PurchasesTableAnnotationComposer,
          $$PurchasesTableCreateCompanionBuilder,
          $$PurchasesTableUpdateCompanionBuilder,
          (Purchase, BaseReferences<_$AppDatabase, $PurchasesTable, Purchase>),
          Purchase,
          PrefetchHooks Function()
        > {
  $$PurchasesTableTableManager(_$AppDatabase db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double> cashTaken = const Value.absent(),
                Value<String> investorId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> memoPhotoPath = const Value.absent(),
                Value<double> returnedCash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                date: date,
                source: source,
                cashTaken: cashTaken,
                investorId: investorId,
                notes: notes,
                memoPhotoPath: memoPhotoPath,
                returnedCash: returnedCash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                Value<String> source = const Value.absent(),
                Value<double> cashTaken = const Value.absent(),
                Value<String> investorId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> memoPhotoPath = const Value.absent(),
                Value<double> returnedCash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                date: date,
                source: source,
                cashTaken: cashTaken,
                investorId: investorId,
                notes: notes,
                memoPhotoPath: memoPhotoPath,
                returnedCash: returnedCash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchasesTable,
      Purchase,
      $$PurchasesTableFilterComposer,
      $$PurchasesTableOrderingComposer,
      $$PurchasesTableAnnotationComposer,
      $$PurchasesTableCreateCompanionBuilder,
      $$PurchasesTableUpdateCompanionBuilder,
      (Purchase, BaseReferences<_$AppDatabase, $PurchasesTable, Purchase>),
      Purchase,
      PrefetchHooks Function()
    >;
typedef $$PurchaseItemsTableCreateCompanionBuilder =
    PurchaseItemsCompanion Function({
      Value<int> id,
      required String purchaseId,
      Value<String> shopName,
      required String itemName,
      required double quantity,
      required double unitPrice,
    });
typedef $$PurchaseItemsTableUpdateCompanionBuilder =
    PurchaseItemsCompanion Function({
      Value<int> id,
      Value<String> purchaseId,
      Value<String> shopName,
      Value<String> itemName,
      Value<double> quantity,
      Value<double> unitPrice,
    });

class $$PurchaseItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseItemsTable> {
  $$PurchaseItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseItemsTable> {
  $$PurchaseItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseItemsTable> {
  $$PurchaseItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shopName =>
      $composableBuilder(column: $table.shopName, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);
}

class $$PurchaseItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseItemsTable,
          PurchaseItem,
          $$PurchaseItemsTableFilterComposer,
          $$PurchaseItemsTableOrderingComposer,
          $$PurchaseItemsTableAnnotationComposer,
          $$PurchaseItemsTableCreateCompanionBuilder,
          $$PurchaseItemsTableUpdateCompanionBuilder,
          (
            PurchaseItem,
            BaseReferences<_$AppDatabase, $PurchaseItemsTable, PurchaseItem>,
          ),
          PurchaseItem,
          PrefetchHooks Function()
        > {
  $$PurchaseItemsTableTableManager(_$AppDatabase db, $PurchaseItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> purchaseId = const Value.absent(),
                Value<String> shopName = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
              }) => PurchaseItemsCompanion(
                id: id,
                purchaseId: purchaseId,
                shopName: shopName,
                itemName: itemName,
                quantity: quantity,
                unitPrice: unitPrice,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String purchaseId,
                Value<String> shopName = const Value.absent(),
                required String itemName,
                required double quantity,
                required double unitPrice,
              }) => PurchaseItemsCompanion.insert(
                id: id,
                purchaseId: purchaseId,
                shopName: shopName,
                itemName: itemName,
                quantity: quantity,
                unitPrice: unitPrice,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseItemsTable,
      PurchaseItem,
      $$PurchaseItemsTableFilterComposer,
      $$PurchaseItemsTableOrderingComposer,
      $$PurchaseItemsTableAnnotationComposer,
      $$PurchaseItemsTableCreateCompanionBuilder,
      $$PurchaseItemsTableUpdateCompanionBuilder,
      (
        PurchaseItem,
        BaseReferences<_$AppDatabase, $PurchaseItemsTable, PurchaseItem>,
      ),
      PurchaseItem,
      PrefetchHooks Function()
    >;
typedef $$TransportCostsTableCreateCompanionBuilder =
    TransportCostsCompanion Function({
      Value<int> id,
      required String purchaseId,
      required String vehicle,
      required double cost,
    });
typedef $$TransportCostsTableUpdateCompanionBuilder =
    TransportCostsCompanion Function({
      Value<int> id,
      Value<String> purchaseId,
      Value<String> vehicle,
      Value<double> cost,
    });

class $$TransportCostsTableFilterComposer
    extends Composer<_$AppDatabase, $TransportCostsTable> {
  $$TransportCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicle => $composableBuilder(
    column: $table.vehicle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransportCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransportCostsTable> {
  $$TransportCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicle => $composableBuilder(
    column: $table.vehicle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransportCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransportCostsTable> {
  $$TransportCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicle =>
      $composableBuilder(column: $table.vehicle, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);
}

class $$TransportCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransportCostsTable,
          TransportCost,
          $$TransportCostsTableFilterComposer,
          $$TransportCostsTableOrderingComposer,
          $$TransportCostsTableAnnotationComposer,
          $$TransportCostsTableCreateCompanionBuilder,
          $$TransportCostsTableUpdateCompanionBuilder,
          (
            TransportCost,
            BaseReferences<_$AppDatabase, $TransportCostsTable, TransportCost>,
          ),
          TransportCost,
          PrefetchHooks Function()
        > {
  $$TransportCostsTableTableManager(
    _$AppDatabase db,
    $TransportCostsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransportCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransportCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransportCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> purchaseId = const Value.absent(),
                Value<String> vehicle = const Value.absent(),
                Value<double> cost = const Value.absent(),
              }) => TransportCostsCompanion(
                id: id,
                purchaseId: purchaseId,
                vehicle: vehicle,
                cost: cost,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String purchaseId,
                required String vehicle,
                required double cost,
              }) => TransportCostsCompanion.insert(
                id: id,
                purchaseId: purchaseId,
                vehicle: vehicle,
                cost: cost,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransportCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransportCostsTable,
      TransportCost,
      $$TransportCostsTableFilterComposer,
      $$TransportCostsTableOrderingComposer,
      $$TransportCostsTableAnnotationComposer,
      $$TransportCostsTableCreateCompanionBuilder,
      $$TransportCostsTableUpdateCompanionBuilder,
      (
        TransportCost,
        BaseReferences<_$AppDatabase, $TransportCostsTable, TransportCost>,
      ),
      TransportCost,
      PrefetchHooks Function()
    >;
typedef $$OtherCostsTableCreateCompanionBuilder =
    OtherCostsCompanion Function({
      Value<int> id,
      required String purchaseId,
      required String description,
      required double cost,
    });
typedef $$OtherCostsTableUpdateCompanionBuilder =
    OtherCostsCompanion Function({
      Value<int> id,
      Value<String> purchaseId,
      Value<String> description,
      Value<double> cost,
    });

class $$OtherCostsTableFilterComposer
    extends Composer<_$AppDatabase, $OtherCostsTable> {
  $$OtherCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OtherCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $OtherCostsTable> {
  $$OtherCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OtherCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OtherCostsTable> {
  $$OtherCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseId => $composableBuilder(
    column: $table.purchaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);
}

class $$OtherCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OtherCostsTable,
          OtherCost,
          $$OtherCostsTableFilterComposer,
          $$OtherCostsTableOrderingComposer,
          $$OtherCostsTableAnnotationComposer,
          $$OtherCostsTableCreateCompanionBuilder,
          $$OtherCostsTableUpdateCompanionBuilder,
          (
            OtherCost,
            BaseReferences<_$AppDatabase, $OtherCostsTable, OtherCost>,
          ),
          OtherCost,
          PrefetchHooks Function()
        > {
  $$OtherCostsTableTableManager(_$AppDatabase db, $OtherCostsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OtherCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OtherCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OtherCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> purchaseId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> cost = const Value.absent(),
              }) => OtherCostsCompanion(
                id: id,
                purchaseId: purchaseId,
                description: description,
                cost: cost,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String purchaseId,
                required String description,
                required double cost,
              }) => OtherCostsCompanion.insert(
                id: id,
                purchaseId: purchaseId,
                description: description,
                cost: cost,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OtherCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OtherCostsTable,
      OtherCost,
      $$OtherCostsTableFilterComposer,
      $$OtherCostsTableOrderingComposer,
      $$OtherCostsTableAnnotationComposer,
      $$OtherCostsTableCreateCompanionBuilder,
      $$OtherCostsTableUpdateCompanionBuilder,
      (OtherCost, BaseReferences<_$AppDatabase, $OtherCostsTable, OtherCost>),
      OtherCost,
      PrefetchHooks Function()
    >;
typedef $$InvestorsTableCreateCompanionBuilder =
    InvestorsCompanion Function({
      required String id,
      required String name,
      Value<double> investedAmount,
      Value<int> durationMonths,
      Value<double> profitPercentage,
      Value<double> dailyEarnings,
      Value<double> monthlyEarnings,
      Value<String> contractType,
      Value<String> investmentType,
      Value<bool> isActive,
      Value<String> startDate,
      Value<double> totalBought,
      Value<double> totalSold,
      Value<double> totalProfit,
      Value<double> remainingBalance,
      Value<double> productValueTotal,
      Value<double> cashInvested,
      Value<double> productInvested,
      Value<int> rowid,
    });
typedef $$InvestorsTableUpdateCompanionBuilder =
    InvestorsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> investedAmount,
      Value<int> durationMonths,
      Value<double> profitPercentage,
      Value<double> dailyEarnings,
      Value<double> monthlyEarnings,
      Value<String> contractType,
      Value<String> investmentType,
      Value<bool> isActive,
      Value<String> startDate,
      Value<double> totalBought,
      Value<double> totalSold,
      Value<double> totalProfit,
      Value<double> remainingBalance,
      Value<double> productValueTotal,
      Value<double> cashInvested,
      Value<double> productInvested,
      Value<int> rowid,
    });

class $$InvestorsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestorsTable> {
  $$InvestorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get investedAmount => $composableBuilder(
    column: $table.investedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMonths => $composableBuilder(
    column: $table.durationMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitPercentage => $composableBuilder(
    column: $table.profitPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dailyEarnings => $composableBuilder(
    column: $table.dailyEarnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyEarnings => $composableBuilder(
    column: $table.monthlyEarnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contractType => $composableBuilder(
    column: $table.contractType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get investmentType => $composableBuilder(
    column: $table.investmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalBought => $composableBuilder(
    column: $table.totalBought,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSold => $composableBuilder(
    column: $table.totalSold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalProfit => $composableBuilder(
    column: $table.totalProfit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingBalance => $composableBuilder(
    column: $table.remainingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get productValueTotal => $composableBuilder(
    column: $table.productValueTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashInvested => $composableBuilder(
    column: $table.cashInvested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get productInvested => $composableBuilder(
    column: $table.productInvested,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvestorsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestorsTable> {
  $$InvestorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get investedAmount => $composableBuilder(
    column: $table.investedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMonths => $composableBuilder(
    column: $table.durationMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitPercentage => $composableBuilder(
    column: $table.profitPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dailyEarnings => $composableBuilder(
    column: $table.dailyEarnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyEarnings => $composableBuilder(
    column: $table.monthlyEarnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contractType => $composableBuilder(
    column: $table.contractType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get investmentType => $composableBuilder(
    column: $table.investmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalBought => $composableBuilder(
    column: $table.totalBought,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSold => $composableBuilder(
    column: $table.totalSold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalProfit => $composableBuilder(
    column: $table.totalProfit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingBalance => $composableBuilder(
    column: $table.remainingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get productValueTotal => $composableBuilder(
    column: $table.productValueTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashInvested => $composableBuilder(
    column: $table.cashInvested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get productInvested => $composableBuilder(
    column: $table.productInvested,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvestorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestorsTable> {
  $$InvestorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get investedAmount => $composableBuilder(
    column: $table.investedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMonths => $composableBuilder(
    column: $table.durationMonths,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitPercentage => $composableBuilder(
    column: $table.profitPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dailyEarnings => $composableBuilder(
    column: $table.dailyEarnings,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monthlyEarnings => $composableBuilder(
    column: $table.monthlyEarnings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contractType => $composableBuilder(
    column: $table.contractType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get investmentType => $composableBuilder(
    column: $table.investmentType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<double> get totalBought => $composableBuilder(
    column: $table.totalBought,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSold =>
      $composableBuilder(column: $table.totalSold, builder: (column) => column);

  GeneratedColumn<double> get totalProfit => $composableBuilder(
    column: $table.totalProfit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingBalance => $composableBuilder(
    column: $table.remainingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get productValueTotal => $composableBuilder(
    column: $table.productValueTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashInvested => $composableBuilder(
    column: $table.cashInvested,
    builder: (column) => column,
  );

  GeneratedColumn<double> get productInvested => $composableBuilder(
    column: $table.productInvested,
    builder: (column) => column,
  );
}

class $$InvestorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestorsTable,
          Investor,
          $$InvestorsTableFilterComposer,
          $$InvestorsTableOrderingComposer,
          $$InvestorsTableAnnotationComposer,
          $$InvestorsTableCreateCompanionBuilder,
          $$InvestorsTableUpdateCompanionBuilder,
          (Investor, BaseReferences<_$AppDatabase, $InvestorsTable, Investor>),
          Investor,
          PrefetchHooks Function()
        > {
  $$InvestorsTableTableManager(_$AppDatabase db, $InvestorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> investedAmount = const Value.absent(),
                Value<int> durationMonths = const Value.absent(),
                Value<double> profitPercentage = const Value.absent(),
                Value<double> dailyEarnings = const Value.absent(),
                Value<double> monthlyEarnings = const Value.absent(),
                Value<String> contractType = const Value.absent(),
                Value<String> investmentType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<double> totalBought = const Value.absent(),
                Value<double> totalSold = const Value.absent(),
                Value<double> totalProfit = const Value.absent(),
                Value<double> remainingBalance = const Value.absent(),
                Value<double> productValueTotal = const Value.absent(),
                Value<double> cashInvested = const Value.absent(),
                Value<double> productInvested = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestorsCompanion(
                id: id,
                name: name,
                investedAmount: investedAmount,
                durationMonths: durationMonths,
                profitPercentage: profitPercentage,
                dailyEarnings: dailyEarnings,
                monthlyEarnings: monthlyEarnings,
                contractType: contractType,
                investmentType: investmentType,
                isActive: isActive,
                startDate: startDate,
                totalBought: totalBought,
                totalSold: totalSold,
                totalProfit: totalProfit,
                remainingBalance: remainingBalance,
                productValueTotal: productValueTotal,
                cashInvested: cashInvested,
                productInvested: productInvested,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<double> investedAmount = const Value.absent(),
                Value<int> durationMonths = const Value.absent(),
                Value<double> profitPercentage = const Value.absent(),
                Value<double> dailyEarnings = const Value.absent(),
                Value<double> monthlyEarnings = const Value.absent(),
                Value<String> contractType = const Value.absent(),
                Value<String> investmentType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<double> totalBought = const Value.absent(),
                Value<double> totalSold = const Value.absent(),
                Value<double> totalProfit = const Value.absent(),
                Value<double> remainingBalance = const Value.absent(),
                Value<double> productValueTotal = const Value.absent(),
                Value<double> cashInvested = const Value.absent(),
                Value<double> productInvested = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestorsCompanion.insert(
                id: id,
                name: name,
                investedAmount: investedAmount,
                durationMonths: durationMonths,
                profitPercentage: profitPercentage,
                dailyEarnings: dailyEarnings,
                monthlyEarnings: monthlyEarnings,
                contractType: contractType,
                investmentType: investmentType,
                isActive: isActive,
                startDate: startDate,
                totalBought: totalBought,
                totalSold: totalSold,
                totalProfit: totalProfit,
                remainingBalance: remainingBalance,
                productValueTotal: productValueTotal,
                cashInvested: cashInvested,
                productInvested: productInvested,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestorsTable,
      Investor,
      $$InvestorsTableFilterComposer,
      $$InvestorsTableOrderingComposer,
      $$InvestorsTableAnnotationComposer,
      $$InvestorsTableCreateCompanionBuilder,
      $$InvestorsTableUpdateCompanionBuilder,
      (Investor, BaseReferences<_$AppDatabase, $InvestorsTable, Investor>),
      Investor,
      PrefetchHooks Function()
    >;
typedef $$RepaymentsTableCreateCompanionBuilder =
    RepaymentsCompanion Function({
      required String id,
      required String investorId,
      required double amount,
      required String date,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$RepaymentsTableUpdateCompanionBuilder =
    RepaymentsCompanion Function({
      Value<String> id,
      Value<String> investorId,
      Value<double> amount,
      Value<String> date,
      Value<String> notes,
      Value<int> rowid,
    });

class $$RepaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $RepaymentsTable> {
  $$RepaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get investorId => $composableBuilder(
    column: $table.investorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RepaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RepaymentsTable> {
  $$RepaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get investorId => $composableBuilder(
    column: $table.investorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RepaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RepaymentsTable> {
  $$RepaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get investorId => $composableBuilder(
    column: $table.investorId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$RepaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RepaymentsTable,
          Repayment,
          $$RepaymentsTableFilterComposer,
          $$RepaymentsTableOrderingComposer,
          $$RepaymentsTableAnnotationComposer,
          $$RepaymentsTableCreateCompanionBuilder,
          $$RepaymentsTableUpdateCompanionBuilder,
          (
            Repayment,
            BaseReferences<_$AppDatabase, $RepaymentsTable, Repayment>,
          ),
          Repayment,
          PrefetchHooks Function()
        > {
  $$RepaymentsTableTableManager(_$AppDatabase db, $RepaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RepaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RepaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> investorId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepaymentsCompanion(
                id: id,
                investorId: investorId,
                amount: amount,
                date: date,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String investorId,
                required double amount,
                required String date,
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepaymentsCompanion.insert(
                id: id,
                investorId: investorId,
                amount: amount,
                date: date,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RepaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RepaymentsTable,
      Repayment,
      $$RepaymentsTableFilterComposer,
      $$RepaymentsTableOrderingComposer,
      $$RepaymentsTableAnnotationComposer,
      $$RepaymentsTableCreateCompanionBuilder,
      $$RepaymentsTableUpdateCompanionBuilder,
      (Repayment, BaseReferences<_$AppDatabase, $RepaymentsTable, Repayment>),
      Repayment,
      PrefetchHooks Function()
    >;
typedef $$FixedAssetsTableCreateCompanionBuilder =
    FixedAssetsCompanion Function({
      required String id,
      required String name,
      required double estimatedValue,
      required String purchaseDate,
      Value<String> imagePath,
      Value<int> rowid,
    });
typedef $$FixedAssetsTableUpdateCompanionBuilder =
    FixedAssetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> estimatedValue,
      Value<String> purchaseDate,
      Value<String> imagePath,
      Value<int> rowid,
    });

class $$FixedAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $FixedAssetsTable> {
  $$FixedAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedValue => $composableBuilder(
    column: $table.estimatedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FixedAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $FixedAssetsTable> {
  $$FixedAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedValue => $composableBuilder(
    column: $table.estimatedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FixedAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FixedAssetsTable> {
  $$FixedAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get estimatedValue => $composableBuilder(
    column: $table.estimatedValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);
}

class $$FixedAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FixedAssetsTable,
          FixedAsset,
          $$FixedAssetsTableFilterComposer,
          $$FixedAssetsTableOrderingComposer,
          $$FixedAssetsTableAnnotationComposer,
          $$FixedAssetsTableCreateCompanionBuilder,
          $$FixedAssetsTableUpdateCompanionBuilder,
          (
            FixedAsset,
            BaseReferences<_$AppDatabase, $FixedAssetsTable, FixedAsset>,
          ),
          FixedAsset,
          PrefetchHooks Function()
        > {
  $$FixedAssetsTableTableManager(_$AppDatabase db, $FixedAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FixedAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FixedAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FixedAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> estimatedValue = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FixedAssetsCompanion(
                id: id,
                name: name,
                estimatedValue: estimatedValue,
                purchaseDate: purchaseDate,
                imagePath: imagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double estimatedValue,
                required String purchaseDate,
                Value<String> imagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FixedAssetsCompanion.insert(
                id: id,
                name: name,
                estimatedValue: estimatedValue,
                purchaseDate: purchaseDate,
                imagePath: imagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FixedAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FixedAssetsTable,
      FixedAsset,
      $$FixedAssetsTableFilterComposer,
      $$FixedAssetsTableOrderingComposer,
      $$FixedAssetsTableAnnotationComposer,
      $$FixedAssetsTableCreateCompanionBuilder,
      $$FixedAssetsTableUpdateCompanionBuilder,
      (
        FixedAsset,
        BaseReferences<_$AppDatabase, $FixedAssetsTable, FixedAsset>,
      ),
      FixedAsset,
      PrefetchHooks Function()
    >;
typedef $$QuickCapturesTableCreateCompanionBuilder =
    QuickCapturesCompanion Function({
      required String id,
      required String timestamp,
      required String note,
      Value<String> imagePath,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$QuickCapturesTableUpdateCompanionBuilder =
    QuickCapturesCompanion Function({
      Value<String> id,
      Value<String> timestamp,
      Value<String> note,
      Value<String> imagePath,
      Value<String> source,
      Value<int> rowid,
    });

class $$QuickCapturesTableFilterComposer
    extends Composer<_$AppDatabase, $QuickCapturesTable> {
  $$QuickCapturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickCapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickCapturesTable> {
  $$QuickCapturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickCapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickCapturesTable> {
  $$QuickCapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$QuickCapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuickCapturesTable,
          QuickCapture,
          $$QuickCapturesTableFilterComposer,
          $$QuickCapturesTableOrderingComposer,
          $$QuickCapturesTableAnnotationComposer,
          $$QuickCapturesTableCreateCompanionBuilder,
          $$QuickCapturesTableUpdateCompanionBuilder,
          (
            QuickCapture,
            BaseReferences<_$AppDatabase, $QuickCapturesTable, QuickCapture>,
          ),
          QuickCapture,
          PrefetchHooks Function()
        > {
  $$QuickCapturesTableTableManager(_$AppDatabase db, $QuickCapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickCapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuickCapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuickCapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickCapturesCompanion(
                id: id,
                timestamp: timestamp,
                note: note,
                imagePath: imagePath,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String timestamp,
                required String note,
                Value<String> imagePath = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickCapturesCompanion.insert(
                id: id,
                timestamp: timestamp,
                note: note,
                imagePath: imagePath,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickCapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuickCapturesTable,
      QuickCapture,
      $$QuickCapturesTableFilterComposer,
      $$QuickCapturesTableOrderingComposer,
      $$QuickCapturesTableAnnotationComposer,
      $$QuickCapturesTableCreateCompanionBuilder,
      $$QuickCapturesTableUpdateCompanionBuilder,
      (
        QuickCapture,
        BaseReferences<_$AppDatabase, $QuickCapturesTable, QuickCapture>,
      ),
      QuickCapture,
      PrefetchHooks Function()
    >;
typedef $$RentBooksTableCreateCompanionBuilder =
    RentBooksCompanion Function({
      required String id,
      required String name,
      Value<int> pageCount,
      Value<int> copies,
      Value<int> rowid,
    });
typedef $$RentBooksTableUpdateCompanionBuilder =
    RentBooksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> pageCount,
      Value<int> copies,
      Value<int> rowid,
    });

class $$RentBooksTableFilterComposer
    extends Composer<_$AppDatabase, $RentBooksTable> {
  $$RentBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get copies => $composableBuilder(
    column: $table.copies,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RentBooksTableOrderingComposer
    extends Composer<_$AppDatabase, $RentBooksTable> {
  $$RentBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get copies => $composableBuilder(
    column: $table.copies,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RentBooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentBooksTable> {
  $$RentBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get copies =>
      $composableBuilder(column: $table.copies, builder: (column) => column);
}

class $$RentBooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentBooksTable,
          RentBook,
          $$RentBooksTableFilterComposer,
          $$RentBooksTableOrderingComposer,
          $$RentBooksTableAnnotationComposer,
          $$RentBooksTableCreateCompanionBuilder,
          $$RentBooksTableUpdateCompanionBuilder,
          (RentBook, BaseReferences<_$AppDatabase, $RentBooksTable, RentBook>),
          RentBook,
          PrefetchHooks Function()
        > {
  $$RentBooksTableTableManager(_$AppDatabase db, $RentBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> copies = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentBooksCompanion(
                id: id,
                name: name,
                pageCount: pageCount,
                copies: copies,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> pageCount = const Value.absent(),
                Value<int> copies = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentBooksCompanion.insert(
                id: id,
                name: name,
                pageCount: pageCount,
                copies: copies,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RentBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentBooksTable,
      RentBook,
      $$RentBooksTableFilterComposer,
      $$RentBooksTableOrderingComposer,
      $$RentBooksTableAnnotationComposer,
      $$RentBooksTableCreateCompanionBuilder,
      $$RentBooksTableUpdateCompanionBuilder,
      (RentBook, BaseReferences<_$AppDatabase, $RentBooksTable, RentBook>),
      RentBook,
      PrefetchHooks Function()
    >;
typedef $$BookRentalsTableCreateCompanionBuilder =
    BookRentalsCompanion Function({
      required String id,
      required String bookName,
      Value<int> pageCount,
      required String customerName,
      required String dateTaken,
      required String expectedReturn,
      Value<String> dateReturned,
      Value<double> cost,
      Value<bool> isPaid,
      Value<int> rowid,
    });
typedef $$BookRentalsTableUpdateCompanionBuilder =
    BookRentalsCompanion Function({
      Value<String> id,
      Value<String> bookName,
      Value<int> pageCount,
      Value<String> customerName,
      Value<String> dateTaken,
      Value<String> expectedReturn,
      Value<String> dateReturned,
      Value<double> cost,
      Value<bool> isPaid,
      Value<int> rowid,
    });

class $$BookRentalsTableFilterComposer
    extends Composer<_$AppDatabase, $BookRentalsTable> {
  $$BookRentalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateReturned => $composableBuilder(
    column: $table.dateReturned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookRentalsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookRentalsTable> {
  $$BookRentalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateReturned => $composableBuilder(
    column: $table.dateReturned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookRentalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookRentalsTable> {
  $$BookRentalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);

  GeneratedColumn<String> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateReturned => $composableBuilder(
    column: $table.dateReturned,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);
}

class $$BookRentalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookRentalsTable,
          BookRental,
          $$BookRentalsTableFilterComposer,
          $$BookRentalsTableOrderingComposer,
          $$BookRentalsTableAnnotationComposer,
          $$BookRentalsTableCreateCompanionBuilder,
          $$BookRentalsTableUpdateCompanionBuilder,
          (
            BookRental,
            BaseReferences<_$AppDatabase, $BookRentalsTable, BookRental>,
          ),
          BookRental,
          PrefetchHooks Function()
        > {
  $$BookRentalsTableTableManager(_$AppDatabase db, $BookRentalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookRentalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookRentalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookRentalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> dateTaken = const Value.absent(),
                Value<String> expectedReturn = const Value.absent(),
                Value<String> dateReturned = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookRentalsCompanion(
                id: id,
                bookName: bookName,
                pageCount: pageCount,
                customerName: customerName,
                dateTaken: dateTaken,
                expectedReturn: expectedReturn,
                dateReturned: dateReturned,
                cost: cost,
                isPaid: isPaid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookName,
                Value<int> pageCount = const Value.absent(),
                required String customerName,
                required String dateTaken,
                required String expectedReturn,
                Value<String> dateReturned = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookRentalsCompanion.insert(
                id: id,
                bookName: bookName,
                pageCount: pageCount,
                customerName: customerName,
                dateTaken: dateTaken,
                expectedReturn: expectedReturn,
                dateReturned: dateReturned,
                cost: cost,
                isPaid: isPaid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookRentalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookRentalsTable,
      BookRental,
      $$BookRentalsTableFilterComposer,
      $$BookRentalsTableOrderingComposer,
      $$BookRentalsTableAnnotationComposer,
      $$BookRentalsTableCreateCompanionBuilder,
      $$BookRentalsTableUpdateCompanionBuilder,
      (
        BookRental,
        BaseReferences<_$AppDatabase, $BookRentalsTable, BookRental>,
      ),
      BookRental,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({Value<int> id, required String name});
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({Value<int> id, Value<String> name});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => CategoriesCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  CategoriesCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$CustomerTypesTableCreateCompanionBuilder =
    CustomerTypesCompanion Function({
      required String id,
      required String label,
      Value<int> iconIndex,
      Value<int> rowid,
    });
typedef $$CustomerTypesTableUpdateCompanionBuilder =
    CustomerTypesCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<int> iconIndex,
      Value<int> rowid,
    });

class $$CustomerTypesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerTypesTable> {
  $$CustomerTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconIndex => $composableBuilder(
    column: $table.iconIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomerTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerTypesTable> {
  $$CustomerTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconIndex => $composableBuilder(
    column: $table.iconIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomerTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerTypesTable> {
  $$CustomerTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get iconIndex =>
      $composableBuilder(column: $table.iconIndex, builder: (column) => column);
}

class $$CustomerTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerTypesTable,
          CustomerType,
          $$CustomerTypesTableFilterComposer,
          $$CustomerTypesTableOrderingComposer,
          $$CustomerTypesTableAnnotationComposer,
          $$CustomerTypesTableCreateCompanionBuilder,
          $$CustomerTypesTableUpdateCompanionBuilder,
          (
            CustomerType,
            BaseReferences<_$AppDatabase, $CustomerTypesTable, CustomerType>,
          ),
          CustomerType,
          PrefetchHooks Function()
        > {
  $$CustomerTypesTableTableManager(_$AppDatabase db, $CustomerTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomerTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomerTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> iconIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerTypesCompanion(
                id: id,
                label: label,
                iconIndex: iconIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                Value<int> iconIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerTypesCompanion.insert(
                id: id,
                label: label,
                iconIndex: iconIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomerTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerTypesTable,
      CustomerType,
      $$CustomerTypesTableFilterComposer,
      $$CustomerTypesTableOrderingComposer,
      $$CustomerTypesTableAnnotationComposer,
      $$CustomerTypesTableCreateCompanionBuilder,
      $$CustomerTypesTableUpdateCompanionBuilder,
      (
        CustomerType,
        BaseReferences<_$AppDatabase, $CustomerTypesTable, CustomerType>,
      ),
      CustomerType,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$CustomerPurchasesTableTableManager get customerPurchases =>
      $$CustomerPurchasesTableTableManager(_db, _db.customerPurchases);
  $$CustomerOrdersTableTableManager get customerOrders =>
      $$CustomerOrdersTableTableManager(_db, _db.customerOrders);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db, _db.purchases);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db, _db.purchaseItems);
  $$TransportCostsTableTableManager get transportCosts =>
      $$TransportCostsTableTableManager(_db, _db.transportCosts);
  $$OtherCostsTableTableManager get otherCosts =>
      $$OtherCostsTableTableManager(_db, _db.otherCosts);
  $$InvestorsTableTableManager get investors =>
      $$InvestorsTableTableManager(_db, _db.investors);
  $$RepaymentsTableTableManager get repayments =>
      $$RepaymentsTableTableManager(_db, _db.repayments);
  $$FixedAssetsTableTableManager get fixedAssets =>
      $$FixedAssetsTableTableManager(_db, _db.fixedAssets);
  $$QuickCapturesTableTableManager get quickCaptures =>
      $$QuickCapturesTableTableManager(_db, _db.quickCaptures);
  $$RentBooksTableTableManager get rentBooks =>
      $$RentBooksTableTableManager(_db, _db.rentBooks);
  $$BookRentalsTableTableManager get bookRentals =>
      $$BookRentalsTableTableManager(_db, _db.bookRentals);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$CustomerTypesTableTableManager get customerTypes =>
      $$CustomerTypesTableTableManager(_db, _db.customerTypes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
