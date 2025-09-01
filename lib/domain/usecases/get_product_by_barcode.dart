import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductByBarcode {
  final ProductRepository repository;

  GetProductByBarcode(this.repository);

  Future<Product?> execute(String barcode) async {
    return await repository.getProductByBarcode(barcode);
  }
}
