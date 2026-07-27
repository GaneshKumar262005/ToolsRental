class ToolModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double pricePerDay;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> imageUrls;
  final bool isAvailable;
  final VendorModel vendor;
  final List<String> specifications;
  final String location;

  ToolModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.pricePerDay,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.imageUrls,
    required this.isAvailable,
    required this.vendor,
    required this.specifications,
    required this.location,
  });
}

class VendorModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String location;
  final double distance;

  VendorModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.distance,
  });
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String imageUrl;
  final int toolCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.imageUrl,
    required this.toolCount,
  });
}

class BookingModel {
  final String id;
  final ToolModel tool;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.tool,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });
}

class ReviewModel {
  final String id;
  final String userName;
  final String userImageUrl;
  final double rating;
  final String comment;
  final DateTime date;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String targetRole; // 'customer' or 'shopowner'
  final DateTime dateTime;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetRole = 'customer',
    required this.dateTime,
    required this.isRead,
  });
}
