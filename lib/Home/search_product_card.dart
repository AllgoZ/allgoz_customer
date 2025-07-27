import 'package:flutter/material.dart';

class SearchProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int cartQuantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const SearchProductCard({
    Key? key,
    required this.product,
    required this.cartQuantity,
    required this.onAdd,
    required this.onRemove,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = screenWidth / 390;

    final bool isAvailable = product['available'] ?? true;
    final int baseQuantity = int.tryParse(product['quantity'].toString()) ?? 1;
    final String unit = product['unit'] ?? 'Gram';
    final double basePrice = (product['price'] as num).toDouble();
    final double totalPrice =
        cartQuantity > 0 ? basePrice * cartQuantity : basePrice;
    final int totalQuantity =
        cartQuantity > 0 ? baseQuantity * cartQuantity : baseQuantity;
    final double quantityInKg =
        unit == "Kg" ? totalQuantity.toDouble() : totalQuantity / 1000;
    final String quantityDisplay = unit == "Gram"
        ? "$totalQuantity Gram"
        : unit == "Kg"
            ? "${quantityInKg.toStringAsFixed(2)} Kg"
            : "$totalQuantity $unit";

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Stack(
        children: [
          Opacity(
            opacity: isAvailable ? 1.0 : 0.5,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(15),
              shadowColor: Colors.black.withOpacity(0.2),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.all(screenWidth * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            product['imageURL'],
                            height: screenHeight * 0.12,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (product['discount'] != null && product['discount'] > 0)
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${product['discount']}% Off",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6 * scaleFactor),
                    Text(
                      product['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13 * scaleFactor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4 * scaleFactor),
                    Text(
                      quantityDisplay,
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4 * scaleFactor),
                    if (product['quantityInKg'] != null &&
                        product['quantityInKg'].toString().trim().isNotEmpty)
                      Text(
                        product['quantityInKg'],
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: 4 * scaleFactor),
                    Text(
                      '₹${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15 * scaleFactor,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 6 * scaleFactor),
                    isAvailable
                        ? cartQuantity == 0
                            ? ElevatedButton(
                                onPressed: onAdd,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                  minimumSize: Size(
                                      screenWidth * 0.4, screenHeight * 0.047),
                                ),
                                child: Text(
                                  "ADD",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 15 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Container(
                                height: screenHeight * 0.047,
                                width: screenWidth * 0.38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                padding:
                                    EdgeInsets.symmetric(horizontal: 4 * scaleFactor),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, color: Colors.green),
                                        iconSize: 25 * scaleFactor,
                                        onPressed: onRemove,
                                      ),
                                      Text(
                                        "$cartQuantity",
                                        style: TextStyle(
                                          fontSize: 25 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, color: Colors.green),
                                        iconSize: 25 * scaleFactor,
                                        onPressed: onAdd,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
          if (!isAvailable)
            Positioned(
              top: 10,
              left: -30,
              child: Transform.rotate(
                angle: -0.785398,
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey,
                  child: Center(
                    child: Text(
                      "OUT OF STOCK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10 * scaleFactor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

