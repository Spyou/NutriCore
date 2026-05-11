import '../entities/product.dart';
import '../../core/utils/result.dart';

abstract class ProductRepository {
  Future<Result<Product>> getProductByBarcode(String barcode);
  Future<Result<List<Product>>> searchProducts(
    String query, {
    int page = 1,
    int pageSize = 20,
  });
}
