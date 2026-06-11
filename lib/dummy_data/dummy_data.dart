import '../models/tool_model.dart';
import '../models/user_model.dart';

class DummyData {
  // Categories
  static List<CategoryModel> categories = [
    CategoryModel(
      id: '1',
      name: 'Drilling Machines',
      icon: '🔧',
      imageUrl: 'assets/images/download.jpg',
      toolCount: 45,
    ),
    CategoryModel(
      id: '2',
      name: 'Concrete Mixers',
      icon: '🏗️',
      imageUrl: 'assets/images/download (1).jpg',
      toolCount: 32,
    ),
    CategoryModel(
      id: '3',
      name: 'Welding Machines',
      icon: '⚡',
      imageUrl: 'assets/images/welding machine.jpg',
      toolCount: 28,
    ),
    CategoryModel(
      id: '4',
      name: 'Generators',
      icon: '🔌',
      imageUrl: 'assets/images/download (2).jpg',
      toolCount: 19,
    ),
    CategoryModel(
      id: '5',
      name: 'Ladders',
      icon: '🪜',
      imageUrl: 'assets/images/download (3).jpg',
      toolCount: 54,
    ),
    CategoryModel(
      id: '6',
      name: 'Cutting Tools',
      icon: '✂️',
      imageUrl: 'assets/images/download (4).jpg',
      toolCount: 67,
    ),
    CategoryModel(
      id: '7',
      name: 'Safety Equipment',
      icon: '⛑️',
      imageUrl: 'assets/images/images.jpg',
      toolCount: 89,
    ),
    CategoryModel(
      id: '8',
      name: 'Excavation Tools',
      icon: '🚜',
      imageUrl: 'assets/images/download (5).jpg',
      toolCount: 23,
    ),
  ];

  // Vendors
  static List<VendorModel> vendors = [
    VendorModel(
      id: 'v1',
      name: 'BuildRight Rentals',
      imageUrl: 'assets/images/download.jpg',
      rating: 4.8,
      reviewCount: 234,
      location: 'T. Nagar',
      distance: 2.5,
    ),
    VendorModel(
      id: 'v2',
      name: 'Construction Pro',
      imageUrl: 'assets/images/download.jpg',
      rating: 4.6,
      reviewCount: 189,
      location: 'Anna Nagar',
      distance: 4.2,
    ),
    VendorModel(
      id: 'v3',
      name: 'ToolMaster',
      imageUrl: 'assets/images/download.jpg',
      rating: 4.9,
      reviewCount: 312,
      location: 'Velachery',
      distance: 1.8,
    ),
    VendorModel(
      id: 'v4',
      name: 'EquipRent',
      imageUrl: 'assets/images/download.jpg',
      rating: 4.5,
      reviewCount: 156,
      location: 'Perambur',
      distance: 5.1,
    ),
  ];

  // Tools
  static List<ToolModel> tools = [
    ToolModel(
      id: 't1',
      name: 'Bosch Rotary Hammer Drill',
      category: 'Drilling Machines',
      description: 'Professional grade rotary hammer drill with SDS-plus chuck. Perfect for concrete and masonry drilling.',
      pricePerDay: 3735.00,
      rating: 4.7,
      reviewCount: 128,
      imageUrl: 'assets/images/download.jpg',
      imageUrls: [
        'assets/images/download.jpg',
        'assets/images/download (1).jpg',
        'assets/images/download (2).jpg',
      ],
      isAvailable: true,
      vendor: vendors[0],
      specifications: ['Power: 800W', 'Max Speed: 1500 RPM', 'Weight: 3.2kg', 'Chuck: SDS-plus'],
      location: 'T. Nagar',
    ),
    ToolModel(
      id: 't2',
      name: 'Portable Concrete Mixer',
      category: 'Concrete Mixers',
      description: 'Heavy-duty portable concrete mixer with 5 cubic feet capacity. Ideal for small to medium construction projects.',
      pricePerDay: 7055.00,
      rating: 4.8,
      reviewCount: 95,
      imageUrl: 'assets/images/download (1).jpg',
      imageUrls: [
        'assets/images/download (1).jpg',
        'assets/images/download (2).jpg',
      ],
      isAvailable: true,
      vendor: vendors[1],
      specifications: ['Capacity: 5 cu ft', 'Motor: 0.5HP', 'Drum Speed: 28 RPM', 'Weight: 120kg'],
      location: 'Anna Nagar',
    ),
    ToolModel(
      id: 't3',
      name: 'MIG Welding Machine',
      category: 'Welding Machines',
      description: 'Professional MIG welding machine with digital display. Suitable for steel, aluminum, and stainless steel.',
      pricePerDay: 5395.00,
      rating: 4.9,
      reviewCount: 156,
      imageUrl: 'assets/images/welding machine.jpg',
      imageUrls: [
        'assets/images/welding machine.jpg',
        'assets/images/images.jpg',
      ],
      isAvailable: false,
      vendor: vendors[2],
      specifications: ['Power: 200A', 'Voltage: 220V', 'Wire Feed: 2-15 m/min', 'Duty Cycle: 60%'],
      location: 'Velachery',
    ),
    ToolModel(
      id: 't4',
      name: 'Diesel Generator 5kW',
      category: 'Generators',
      description: 'Reliable diesel generator providing 5kW continuous power. Perfect for construction sites and events.',
      pricePerDay: 9960.00,
      rating: 4.6,
      reviewCount: 78,
      imageUrl: 'assets/images/download (2).jpg',
      imageUrls: [
        'assets/images/download (2).jpg',
        'assets/images/download.jpg',
      ],
      isAvailable: true,
      vendor: vendors[0],
      specifications: ['Power: 5kW', 'Fuel: Diesel', 'Tank: 15L', 'Runtime: 8 hours'],
      location: 'T. Nagar',
    ),
    ToolModel(
      id: 't5',
      name: 'Aluminum Extension Ladder',
      category: 'Ladders',
      description: 'Lightweight aluminum extension ladder with 24ft reach. Non-slip feet and stabilizer bar included.',
      pricePerDay: 2075.00,
      rating: 4.5,
      reviewCount: 203,
      imageUrl: 'assets/images/download (3).jpg',
      imageUrls: [
        'assets/images/download (3).jpg',
        'assets/images/images.jpg',
      ],
      isAvailable: true,
      vendor: vendors[3],
      specifications: ['Height: 24ft', 'Material: Aluminum', 'Weight: 15kg', 'Load: 300lbs'],
      location: 'Perambur',
    ),
    ToolModel(
      id: 't6',
      name: 'Angle Grinder 9-inch',
      category: 'Cutting Tools',
      description: 'Powerful 9-inch angle grinder for cutting and grinding metal, stone, and concrete.',
      pricePerDay: 2905.00,
      rating: 4.7,
      reviewCount: 167,
      imageUrl: 'assets/images/download (4).jpg',
      imageUrls: [
        'assets/images/download (4).jpg',
        'assets/images/download.jpg',
      ],
      isAvailable: true,
      vendor: vendors[2],
      specifications: ['Power: 2000W', 'Disc Size: 9"', 'Speed: 6500 RPM', 'Weight: 4.5kg'],
      location: 'Velachery',
    ),
    ToolModel(
      id: 't7',
      name: 'Safety Helmet Kit',
      category: 'Safety Equipment',
      description: 'Complete safety kit including helmet, safety glasses, gloves, and high-visibility vest.',
      pricePerDay: 1245.00,
      rating: 4.8,
      reviewCount: 289,
      imageUrl: 'assets/images/images.jpg',
      imageUrls: [
        'assets/images/images.jpg',
        'assets/images/download (5).jpg',
      ],
      isAvailable: true,
      vendor: vendors[1],
      specifications: ['Helmet: ANSI certified', 'Glasses: UV protection', 'Gloves: Cut resistant', 'Vest: Class 2'],
      location: 'Anna Nagar',
    ),
    ToolModel(
      id: 't8',
      name: 'Mini Excavator',
      category: 'Excavation Tools',
      description: 'Compact mini excavator perfect for small construction sites, landscaping, and utility work.',
      pricePerDay: 29050.00,
      rating: 4.9,
      reviewCount: 45,
      imageUrl: 'assets/images/download (5).jpg',
      imageUrls: [
        'assets/images/download (5).jpg',
        'assets/images/download (1).jpg',
      ],
      isAvailable: true,
      vendor: vendors[0],
      specifications: ['Weight: 1.5 tons', 'Dig Depth: 8ft', 'Bucket: 0.04 cu yd', 'Width: 3ft'],
      location: 'T. Nagar',
    ),
  ];

  // Reviews
  static List<ReviewModel> reviews = [
    ReviewModel(
      id: 'r1',
      userName: 'John Smith',
      userImageUrl: 'assets/images/download.jpg',
      rating: 5.0,
      comment: 'Excellent tool! Worked perfectly for my project. Will definitely rent again.',
      date: DateTime(2024, 1, 15),
    ),
    ReviewModel(
      id: 'r2',
      userName: 'Sarah Johnson',
      userImageUrl: 'assets/images/download.jpg',
      rating: 4.5,
      comment: 'Good condition and easy to use. Delivery was on time.',
      date: DateTime(2024, 1, 10),
    ),
    ReviewModel(
      id: 'r3',
      userName: 'Mike Wilson',
      userImageUrl: 'assets/images/download.jpg',
      rating: 4.0,
      comment: 'Decent equipment but could be cleaner. Overall satisfied.',
      date: DateTime(2024, 1, 5),
    ),
    ReviewModel(
      id: 'r4',
      userName: 'Emily Davis',
      userImageUrl: 'assets/images/download.jpg',
      rating: 5.0,
      comment: 'Top-notch service! The tool was in perfect condition.',
      date: DateTime(2024, 1, 2),
    ),
  ];

  // Notifications
  static List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n1',
      title: 'Booking Confirmed',
      message: 'Your booking for Bosch Rotary Hammer Drill has been confirmed.',
      type: 'booking',
      dateTime: DateTime(2024, 1, 20, 10, 30),
      isRead: false,
    ),
    NotificationModel(
      id: 'n2',
      title: 'Return Reminder',
      message: 'Your rental is due for return tomorrow. Please arrange pickup.',
      type: 'reminder',
      dateTime: DateTime(2024, 1, 19, 9, 0),
      isRead: false,
    ),
    NotificationModel(
      id: 'n3',
      title: 'Special Offer',
      message: 'Get 20% off on all concrete mixers this weekend!',
      type: 'offer',
      dateTime: DateTime(2024, 1, 18, 14, 0),
      isRead: true,
    ),
    NotificationModel(
      id: 'n4',
      title: 'Payment Successful',
      message: 'Your payment of ₹7,055.00 has been processed successfully.',
      type: 'payment',
      dateTime: DateTime(2024, 1, 17, 16, 45),
      isRead: true,
    ),
  ];

  // User
  static UserModel currentUser = UserModel(
    id: 'u1',
    name: 'Alex Thompson',
    email: 'alex.thompson@email.com',
    phone: '+1 234 567 8900',
    imageUrl: 'assets/images/download.jpg',
    location: 'Chennai, Tamil Nadu',
  );

  // Bookings
  static List<BookingModel> bookings = [
    BookingModel(
      id: 'b1',
      tool: tools[0],
      startDate: DateTime(2024, 1, 25),
      endDate: DateTime(2024, 1, 28),
      totalPrice: 11205.00,
      status: 'active',
      createdAt: DateTime(2024, 1, 20),
    ),
    BookingModel(
      id: 'b2',
      tool: tools[1],
      startDate: DateTime(2024, 1, 15),
      endDate: DateTime(2024, 1, 18),
      totalPrice: 21165.00,
      status: 'completed',
      createdAt: DateTime(2024, 1, 10),
    ),
    BookingModel(
      id: 'b3',
      tool: tools[4],
      startDate: DateTime(2024, 1, 5),
      endDate: DateTime(2024, 1, 7),
      totalPrice: 4150.00,
      status: 'completed',
      createdAt: DateTime(2024, 1, 3),
    ),
  ];

  // Onboarding data
  static List<OnboardingData> onboardingData = [
    OnboardingData(
      title: 'Rent Smart',
      description: 'Find the perfect construction tools for your project at affordable prices.',
      imageUrl: 'assets/images/download.jpg',
    ),
    OnboardingData(
      title: 'Build Faster',
      description: 'Get equipment delivered to your site and focus on what matters most.',
      imageUrl: 'assets/images/download (1).jpg',
    ),
    OnboardingData(
      title: 'Save Money',
      description: 'No need to buy expensive tools. Rent only when you need them.',
      imageUrl: 'assets/images/images.jpg',
    ),
  ];
}

class OnboardingData {
  final String title;
  final String description;
  final String imageUrl;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}
