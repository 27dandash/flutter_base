import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/base/base_remote_source.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/datasources/products_remote_data_source.dart';
import '../../domain/entities/product_entity.dart';
import '../mappers/product_mapper.dart';
import '../models/product_model.dart';

/// Concrete data source — talks to the backend via [BaseRemoteSource.request].
///
/// Notes
///   - Registered as `ProductsRemoteDataSource` (the abstract type) so the
///     repository depends on the contract, not the implementation.
///   - Every call uses the unified [request] helper — pass the verb +
///     named params, get back `Either<Failure, T>`.
///   - We map Model → Entity here so callers never see the wire shape.
@LazySingleton(as: ProductsRemoteDataSource)
class ProductsRemoteDataSourceImpl extends BaseRemoteSource
    implements ProductsRemoteDataSource {
  ProductsRemoteDataSourceImpl();

  // ── GET list — query params ──────────────────────────────────────
  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    String? search,
  }) {
    return request<List<ProductEntity>>(
      method: HttpMethod.get,
      endpoint: ApiEndpoints.products,

      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      fromJson: _parseProductList,
    );
  }

  // ── GET single ───────────────────────────────────────────────────
  @override
  Future<Either<Failure, ProductEntity>> getProductById(int id) {
    return request<ProductEntity>(
      method: HttpMethod.get,
      endpoint: ApiEndpoints.productById(id),
      fromJson: _parseProduct,
    );
  }

  // ── POST create — body payload ───────────────────────────────────
  @override
  Future<Either<Failure, ProductEntity>> createProduct({
    required String name,
    required String description,
    required double price,
  }) {
    return request<ProductEntity>(
      method: HttpMethod.post,
      endpoint: ApiEndpoints.products,
      body: {'name': name, 'description': description, 'price': price},
      fromJson: _parseProduct,
    );
  }

  // ── PUT update — body payload ────────────────────────────────────
  @override
  Future<Either<Failure, ProductEntity>> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
  }) {
    return request<ProductEntity>(
      method: HttpMethod.put,
      endpoint: ApiEndpoints.productById(id),
      body: {'name': name, 'description': description, 'price': price},
      fromJson: _parseProduct,
    );
  }

  // ── DELETE — no response body to care about ──────────────────────
  @override
  Future<Either<Failure, Unit>> deleteProduct(int id) {
    return request<Unit>(
      method: HttpMethod.delete,
      endpoint: ApiEndpoints.productById(id),
      // dartz's `unit` is the void-equivalent — fold treats `Right(unit)`
      // as "success, no value to surface".
      fromJson: (_) => unit,
    );
  }

  // ── Parsers (kept private to this file) ──────────────────────────

  static List<ProductEntity> _parseProductList(dynamic json) {
    final list = (json is Map ? json['data'] : json) as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .map((m) => m.toEntity())
        .toList();
  }

  static ProductEntity _parseProduct(dynamic json) {
    final data = json is Map<String, dynamic>
        ? (json['data'] ?? json) as Map<String, dynamic>
        : <String, dynamic>{};
    return ProductModel.fromJson(data).toEntity();
  }
}
