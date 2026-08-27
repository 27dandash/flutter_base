// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../../features/products/data/datasources/products_remote_data_source_impl.dart'
    as _i126;
import '../../../features/products/data/repositories/products_repository_impl.dart'
    as _i50;
import '../../../features/products/domain/datasources/products_remote_data_source.dart'
    as _i947;
import '../../../features/products/domain/repositories/products_repository.dart'
    as _i239;
import '../../../features/products/domain/usecases/create_product_usecase.dart'
    as _i1024;
import '../../../features/products/domain/usecases/delete_product_usecase.dart'
    as _i975;
import '../../../features/products/domain/usecases/get_product_details_usecase.dart'
    as _i173;
import '../../../features/products/domain/usecases/get_products_usecase.dart'
    as _i533;
import '../../../features/products/presentation/imports/products_imports.dart'
    as _i121;
import '../../network/auth/token_storage.dart' as _i235;
import '../../state/paginated/lookup_remote_source.dart' as _i934;
import '../cubits/user_cubit/user_cubit.dart' as _i996;
import 'setup_service_locators.dart' as _i1071;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreInfrastructureModule = _$CoreInfrastructureModule();
    gh.lazySingleton<_i235.TokenStorage>(
      () => coreInfrastructureModule.tokenStorage,
    );
    gh.lazySingleton<_i934.LookupRemoteSource>(
      () => _i934.LookupRemoteSource(),
    );
    gh.lazySingleton<_i947.ProductsRemoteDataSource>(
      () => _i126.ProductsRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i239.ProductsRepository>(
      () => _i50.ProductsRepositoryImpl(gh<_i947.ProductsRemoteDataSource>()),
    );
    gh.lazySingleton<_i996.UserCubit>(
      () => _i996.UserCubit(gh<_i235.TokenStorage>()),
    );
    gh.factory<_i1024.CreateProductUseCase>(
      () => _i1024.CreateProductUseCase(gh<_i239.ProductsRepository>()),
    );
    gh.factory<_i975.DeleteProductUseCase>(
      () => _i975.DeleteProductUseCase(gh<_i239.ProductsRepository>()),
    );
    gh.factory<_i173.GetProductDetailsUseCase>(
      () => _i173.GetProductDetailsUseCase(gh<_i239.ProductsRepository>()),
    );
    gh.factory<_i533.GetProductsUseCase>(
      () => _i533.GetProductsUseCase(gh<_i239.ProductsRepository>()),
    );
    gh.factory<_i121.ProductDetailsCubit>(
      () => _i121.ProductDetailsCubit(gh<_i173.GetProductDetailsUseCase>()),
    );
    gh.factory<_i121.ProductsCubit>(
      () => _i121.ProductsCubit(
        gh<_i533.GetProductsUseCase>(),
        gh<_i1024.CreateProductUseCase>(),
        gh<_i975.DeleteProductUseCase>(),
      ),
    );
    return this;
  }
}

class _$CoreInfrastructureModule extends _i1071.CoreInfrastructureModule {}
