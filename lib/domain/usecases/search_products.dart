import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../../core/utils/result.dart';

class SearchProducts {
  final ProductRepository repository;

  SearchProducts(this.repository);

  Future<Result<List<Product>>> execute(String query) async {
    return await repository.searchProducts(query);
  }
}
