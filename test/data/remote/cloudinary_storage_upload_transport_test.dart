import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory/core/storage/cloudinary_config.dart';
import 'package:inventory/data/remote/cloudinary_storage_upload_transport.dart';
import 'package:test/test.dart';

void main() {
  group('CloudinaryStorageUploadTransport', () {
    late Directory tempDir;
    late File sampleFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cloudinary_test');
      sampleFile = File('${tempDir.path}/test_image.jpg');
      await sampleFile.writeAsBytes([0, 1, 2, 3, 4, 5]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('upload sends multipart request to Cloudinary endpoint with preset and folder', () async {
      var requestReceived = false;

      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('api.cloudinary.com')) {
          requestReceived = true;
          expect(request.method, 'POST');
          return http.Response(
            jsonEncode({
              'secure_url': 'https://res.cloudinary.com/test-cloud/image/upload/v12345/inventory_app/shop_1/products/prod_001.jpg',
              'public_id': 'inventory_app/shop_1/products/prod_001',
              'bytes': 1024,
              'format': 'jpg',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final transport = CloudinaryStorageUploadTransport(
        config: const CloudinaryConfig(
          cloudName: 'test-cloud',
          uploadPreset: 'test_preset',
          folderPrefix: 'inventory_app',
        ),
        httpClient: mockClient,
      );

      final result = await transport.upload(
        bucketName: 'product_image',
        storagePath: 'inventory_app/shop_1/products/prod_001.jpg',
        localPath: sampleFile.path,
      );

      expect(requestReceived, isTrue);
      expect(result.isOk, isTrue);
    });

    test('createSignedUrl generates valid Cloudinary CDN transformation URL', () async {
      final transport = CloudinaryStorageUploadTransport(
        config: const CloudinaryConfig(
          cloudName: 'test-cloud',
        ),
      );

      final result = await transport.createSignedUrl(
        bucketName: 'product_image',
        storagePath: 'inventory_app/shop_1/products/prod_001',
      );

      expect(result.isOk, isTrue);
      expect(
        result.unwrap(),
        'https://res.cloudinary.com/test-cloud/image/upload/q_auto,f_auto/inventory_app/shop_1/products/prod_001',
      );
    });

    test('createSignedUrl automatically prepends structured entity folder if relative path given', () async {
      final transport = CloudinaryStorageUploadTransport(
        config: const CloudinaryConfig(
          cloudName: 'uppmajet',
          folderPrefix: 'inventory_app',
        ),
      );

      final result = await transport.createSignedUrl(
        bucketName: 'product_image',
        storagePath: 'prod_123/img_456.jpg',
      );

      expect(result.isOk, isTrue);
      expect(
        result.unwrap(),
        'https://res.cloudinary.com/uppmajet/image/upload/q_auto,f_auto/inventory_app/default_shop/products/prod_123/img_456',
      );
    });

    test('delete sends signed request to Cloudinary destroy endpoint', () async {
      String? requestedUrl;
      Map<String, String>? requestFields;

      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestFields = request.bodyFields;
        return http.Response(jsonEncode({'result': 'ok'}), 200);
      });

      final transport = CloudinaryStorageUploadTransport(
        config: const CloudinaryConfig(
          cloudName: 'uppmajet',
          apiKey: 'test_api_key',
          apiSecret: 'test_api_secret',
        ),
        httpClient: mockClient,
      );

      final result = await transport.delete(
        bucketName: 'customer_image',
        storagePath: 'cust_123/img_456.jpg',
      );

      expect(result.isOk, isTrue);
      expect(requestedUrl, 'https://api.cloudinary.com/v1_1/uppmajet/image/destroy');
      expect(requestFields?['api_key'], 'test_api_key');
      expect(requestFields?['public_id'], 'inventory_app/default_shop/customers/cust_123/img_456');
      expect(requestFields?['signature'], isNotEmpty);
    });
  });
}
