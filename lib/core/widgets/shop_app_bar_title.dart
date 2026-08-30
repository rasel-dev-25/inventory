import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import 'shop_logo.dart';

class ShopAppBarTitle extends StatefulWidget {
  final String pageTitle;

  const ShopAppBarTitle({required this.pageTitle, super.key});

  @override
  State<ShopAppBarTitle> createState() => _ShopAppBarTitleState();
}

class _ShopAppBarTitleState extends State<ShopAppBarTitle> {
  late final Future<ShopRow?> _shopFuture;

  @override
  void initState() {
    super.initState();
    final db = Get.find<AppDatabase>();
    _shopFuture = db.select(db.shops).getSingleOrNull();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopRow?>(
      future: _shopFuture,
      builder: (context, snapshot) {
        final shopName = snapshot.data?.name ?? 'appTitle'.tr;
        final date = DateFormat.yMMMd().format(DateTime.now());
        final fgColor = Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            shopLogo(size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.pageTitle} · $date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
