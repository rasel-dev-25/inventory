/// Cloudinary configuration and dynamic URL transformation helper.
///
/// Cloudinary provides 25GB free managed storage and a worldwide CDN.
/// Photos are uploaded with an unsigned preset directly to hierarchical folders:
/// `inventory_app/<shopId>/<entityType>/`
///
/// Transformations (e.g. auto WebP, dynamic thumbnail resizing) are generated
/// on-the-fly via CDN URL paths with zero need for duplicate image uploads.
class CloudinaryConfig {
  /// Default Cloud Name configured for the application.
  /// Can be overridden via Settings or runtime constructor.
  static const String defaultCloudName = 'uppmajet';

  /// Default Unsigned Upload Preset name.
  static const String defaultUploadPreset = 'inventory_app_preset';

  /// Root folder prefix for the app.
  static const String defaultFolderPrefix = 'inventory_app';

  /// Optional API Key and Secret for signed management operations like deletion.
  static const String defaultApiKey = '762998835494618';
  static const String defaultApiSecret = 'rB0IfyJ0AhukIwZ0_CyLI7cVcF8';

  final String cloudName;
  final String uploadPreset;
  final String folderPrefix;
  final String apiKey;
  final String apiSecret;

  const CloudinaryConfig({
    this.cloudName = defaultCloudName,
    this.uploadPreset = defaultUploadPreset,
    this.folderPrefix = defaultFolderPrefix,
    this.apiKey = defaultApiKey,
    this.apiSecret = defaultApiSecret,
  });

  /// Computes the folder path for a given entity type and shop.
  /// Examples:
  /// - `inventory_app/shop_123/products`
  /// - `inventory_app/shop_123/customers`
  /// - `inventory_app/shop_123/fixed_assets`
  /// - `inventory_app/shop_123/quick_captures`
  String folderFor({
    required String entityType,
    String shopId = 'default_shop',
  }) {
    final cleanType = _cleanEntityType(entityType);
    return '$folderPrefix/$shopId/$cleanType';
  }

  /// Transforms an entity type name into a clean folder subpath.
  static String _cleanEntityType(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'product_image':
      case 'products':
        return 'products';
      case 'customer_image':
      case 'customers':
        return 'customers';
      case 'fixed_asset_image':
      case 'fixed_assets':
      case 'assets':
        return 'fixed_assets';
      case 'quick_capture':
      case 'quick_captures':
        return 'quick_captures';
      default:
        return entityType.replaceAll('_', '-');
    }
  }

  /// Constructs a thumbnail URL (200x200 crop, auto-format WebP, auto-quality).
  static String getThumbnailUrl(
    String urlOrPublicId, {
    String cloudName = defaultCloudName,
    int width = 200,
    int height = 200,
  }) {
    return transformUrl(
      urlOrPublicId,
      cloudName: cloudName,
      transformation: 'c_fill,w_$width,h_$height,g_auto,q_auto,f_auto',
    );
  }

  /// Constructs an optimized preview URL (max 1200px, auto-format, auto-quality).
  static String getPreviewUrl(
    String urlOrPublicId, {
    String cloudName = defaultCloudName,
    int maxWidth = 1200,
    int maxHeight = 1200,
  }) {
    return transformUrl(
      urlOrPublicId,
      cloudName: cloudName,
      transformation: 'c_limit,w_$maxWidth,h_$maxHeight,q_auto,f_auto',
    );
  }

  /// Generates a Cloudinary transformation URL from a secure URL or public ID.
  static String transformUrl(
    String urlOrPublicId, {
    required String transformation,
    String cloudName = defaultCloudName,
  }) {
    if (urlOrPublicId.isEmpty) return '';

    // If it's already a full Cloudinary URL
    if (urlOrPublicId.contains('res.cloudinary.com')) {
      // e.g. https://res.cloudinary.com/cloud_name/image/upload/v1234/folder/img.jpg
      final uploadIndex = urlOrPublicId.indexOf('/upload/');
      if (uploadIndex != -1) {
        final prefix = urlOrPublicId.substring(0, uploadIndex + 8);
        final suffix = urlOrPublicId.substring(uploadIndex + 8);
        // Avoid duplicate transformations
        if (suffix.startsWith('c_') || suffix.startsWith('w_') || suffix.startsWith('q_')) {
          final slashIndex = suffix.indexOf('/');
          if (slashIndex != -1) {
            return '$prefix$transformation/${suffix.substring(slashIndex + 1)}';
          }
        }
        return '$prefix$transformation/$suffix';
      }
      return urlOrPublicId;
    }

    // If it's a public_id (e.g. "inventory_app/shop_1/products/xyz")
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformation/$urlOrPublicId';
  }

  /// Checks if a given string is a Cloudinary remote URL.
  static bool isCloudinaryUrl(String url) {
    return url.contains('res.cloudinary.com') || url.contains('cloudinary.com');
  }
}
