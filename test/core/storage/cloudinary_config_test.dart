import 'package:inventory/core/storage/cloudinary_config.dart';
import 'package:test/test.dart';

void main() {
  group('CloudinaryConfig', () {
    const config = CloudinaryConfig(
      cloudName: 'my-shop-cloud',
      uploadPreset: 'my_preset',
      folderPrefix: 'inventory_app',
    );

    test('generates correct folder hierarchy for various entity types', () {
      expect(
        config.folderFor(entityType: 'product_image', shopId: 'shop_001'),
        'inventory_app/shop_001/products',
      );
      expect(
        config.folderFor(entityType: 'customer_image', shopId: 'shop_001'),
        'inventory_app/shop_001/customers',
      );
      expect(
        config.folderFor(entityType: 'fixed_asset_image', shopId: 'shop_001'),
        'inventory_app/shop_001/fixed_assets',
      );
      expect(
        config.folderFor(entityType: 'quick_capture', shopId: 'shop_001'),
        'inventory_app/shop_001/quick_captures',
      );
    });

    test('transforms thumbnail URL correctly with dynamic crop and auto-format', () {
      const publicId = 'inventory_app/shop_1/products/prod_123';
      final thumbUrl = CloudinaryConfig.getThumbnailUrl(
        publicId,
        cloudName: 'my-shop-cloud',
        width: 150,
        height: 150,
      );

      expect(
        thumbUrl,
        'https://res.cloudinary.com/my-shop-cloud/image/upload/c_fill,w_150,h_150,g_auto,q_auto,f_auto/inventory_app/shop_1/products/prod_123',
      );
    });

    test('transforms preview URL correctly with max boundary', () {
      const publicId = 'inventory_app/shop_1/products/prod_123';
      final previewUrl = CloudinaryConfig.getPreviewUrl(
        publicId,
        cloudName: 'my-shop-cloud',
        maxWidth: 1000,
        maxHeight: 1000,
      );

      expect(
        previewUrl,
        'https://res.cloudinary.com/my-shop-cloud/image/upload/c_limit,w_1000,h_1000,q_auto,f_auto/inventory_app/shop_1/products/prod_123',
      );
    });

    test('detects Cloudinary URLs accurately', () {
      expect(
        CloudinaryConfig.isCloudinaryUrl('https://res.cloudinary.com/demo/image/upload/sample.jpg'),
        isTrue,
      );
      expect(
        CloudinaryConfig.isCloudinaryUrl('https://supabase.co/storage/v1/object/public/bucket/img.jpg'),
        isFalse,
      );
      expect(
        CloudinaryConfig.isCloudinaryUrl('/data/user/0/app/images/local.jpg'),
        isFalse,
      );
    });
  });
}
