import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../models/tool_model.dart';
import '../services/firebase_service.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/vendor_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_image.dart';
import 'booking_screen.dart';
import 'vendor_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final bool firestoreConnected;

  const HomeScreen({
    super.key,
    required this.userName,
    this.firestoreConnected = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBanner = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;
  String _popularFilter = '🔥 Most Liked';

  List<ToolModel> get _filteredTools {
    if (_searchQuery.isEmpty) return DummyData.tools;
    return DummyData.tools.where((tool) {
      return tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<ToolModel> get _popularTools {
    final list = List<ToolModel>.from(DummyData.tools);
    if (_popularFilter == '⭐ Top Rated') {
      return list.where((t) => t.rating >= 4.8).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_popularFilter == '🔥 Most Liked') {
      list.sort((a, b) {
        final scoreA = (a.rating * 100) + a.reviewCount;
        final scoreB = (b.rating * 100) + b.reviewCount;
        return scoreB.compareTo(scoreA);
      });
      return list;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadRealCustomerRatings();
  }

  Future<void> _loadRealCustomerRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cloudReviews = await FirebaseService().fetchToolRatings();
      final List<String> localReviewsRaw = prefs.getStringList('local_customer_reviews') ?? [];
      
      List<Map<String, dynamic>> allReviews = [...cloudReviews];
      for (var raw in localReviewsRaw) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            allReviews.add(decoded);
          }
        } catch (_) {}
      }

      Map<String, List<double>> toolRatingsMap = {};
      for (var rev in allReviews) {
        final tId = rev['toolId']?.toString();
        final r = (rev['rating'] as num?)?.toDouble();
        if (tId != null && r != null && r > 0) {
          toolRatingsMap.putIfAbsent(tId, () => []).add(r);
        }
      }

      for (var tool in DummyData.tools) {
        if (toolRatingsMap.containsKey(tool.id)) {
          final ratings = toolRatingsMap[tool.id]!;
          double sum = ratings.reduce((a, b) => a + b);
          double newAvg = ((tool.rating * tool.reviewCount) + sum) / (tool.reviewCount + ratings.length);
          tool.rating = double.parse(newAvg.toStringAsFixed(1));
          tool.reviewCount += ratings.length;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _gradientText(String text, TextStyle? baseStyle) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: (baseStyle ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryWhite,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.yellowBlackGradient,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppTheme.primaryWhite, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                DummyData.currentUser.location,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.primaryWhite),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: AppTheme.primaryWhite),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hi, ${DummyData.currentUser.name}!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.primaryWhite,
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchBarWidget(
                          hintText: 'Search tools, categories...',
                          controller: _searchController,
                          readOnly: false,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _showSearchResults = value.isNotEmpty;
                            });
                          },
                        ),
                        if (_showSearchResults) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
                            ),
                            child: _filteredTools.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, color: AppTheme.mediumGray.withOpacity(0.5), size: 28),
                                        const SizedBox(width: 12),
                                        Text('No results for "$_searchQuery"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredTools.length > 5 ? 5 : _filteredTools.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.mediumGray.withOpacity(0.15)),
                                    itemBuilder: (context, index) {
                                      final tool = _filteredTools[index];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: AppImage(imageUrl: tool.imageUrl, width: 52, height: 52, fit: BoxFit.cover)),
                                        title: Text(tool.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                        subtitle: Text(tool.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray)),
                                        trailing: ShaderMask(
                                          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]).createShader(bounds),
                                          child: Text('₹${tool.pricePerDay}/day', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        onTap: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _showSearchResults = false;
                                          });
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(tool: tool)));
                                        },
                                      );
                                    },
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),

                    // ✅ Attractive gradient stat cards
                    Row(
                      children: [
                        // Active Rentals card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.build,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _showSearchResults
                                      ? '${_filteredTools.length}'
                                      : '3',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  _showSearchResults
                                      ? 'Results Found'
                                      : 'Active Rentals',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Total Spent card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF11998e).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.currency_rupee,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '₹37,350',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const Text(
                                  'Total Spent',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Carousel
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 180,
                        viewportFraction: 0.9,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        enlargeCenterPage: true,
                        onPageChanged: (index, reason) {
                          setState(() => _currentBanner = index);
                        },
                      ),
                      items: [
                        _buildBanner(
                          'Get 20% Off',
                          'On all concrete mixers this weekend',
                          'assets/images/banner1.jpg',
                          AppTheme.primaryYellow,
                        ),
                        _buildBanner(
                          'New Tools Added',
                          'Check out our latest equipment',
                          'assets/images/banner2.jpg',
                          AppTheme.accentBlue,
                        ),
                        _buildBanner(
                          'Free Delivery',
                          'On orders above ₹8,300',
                          'assets/images/banner3.jpg',
                          AppTheme.accentGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Banner dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBanner == index ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentBanner == index
                                ? AppTheme.primaryYellow
                                : AppTheme.mediumGray.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _gradientText('Categories',
                            Theme.of(context).textTheme.headlineSmall),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/categories'),
                          child: Text('See All',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.primaryYellow)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ✅ Fixed overflow in category list
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: DummyData.categories.length,
                        itemBuilder: (context, index) {
                          final category = DummyData.categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 110,
                              child: CategoryCard(
                                category: category,
                                onTap: () => Navigator.pushNamed(
                                    context, '/categories'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Popular Tools (Most Liked & Suggested)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _gradientText('Popular Tools',
                            Theme.of(context).textTheme.headlineSmall),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/categories'),
                          child: Text('See All',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.primaryYellow)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Filter ChoiceChips for Most Liked / Suggested Tools
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          '🔥 Most Liked',
                          '⭐ Top Rated',
                          'All Tools',
                        ].map((chip) {
                          final bool selected = _popularFilter == chip;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                chip,
                                style: TextStyle(
                                  color: selected ? Colors.black : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: selected,
                              selectedColor: AppTheme.primaryYellow,
                              backgroundColor: const Color(0xFF2A2A2A),
                              onSelected: (_) {
                                setState(() => _popularFilter = chip);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 1200 ? 4 : (width >= 750 ? 3 : 2);
                        final childAspectRatio = width >= 1200 ? 0.90 : (width >= 750 ? 0.85 : 0.58);
                        final displayList = _popularTools;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final tool = displayList[index];
                            return _buildToolCard(tool);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    _gradientText('Featured Vendors',
                        Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),

                    ...DummyData.vendors.map((vendor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VendorCard(
                          vendor: vendor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorDetailScreen(vendor: vendor),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _gradientText('Recent Reviews',
                            Theme.of(context).textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorDetailScreen(vendor: DummyData.vendors.first),
                              ),
                            );
                          },
                          child: Text('See All',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.primaryYellow)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ...DummyData.reviews.take(2).map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorDetailScreen(vendor: DummyData.vendors.first),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(review.userImageUrl),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review.userName,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: AppTheme.primaryYellow,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                review.rating.toString(),
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  review.comment,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
  floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.yellowBlackGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryYellow.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/categories'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.search, color: AppTheme.primaryWhite),
        ),
      ),
    );
  }

  Widget _buildToolCard(ToolModel tool) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final imageHeight = isMobile ? 102.0 : 135.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(tool: tool),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppTheme.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.primaryYellow.withOpacity(0.2)
                : AppTheme.mediumGray.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medium Image Container (Splash/Product style) with Most Liked Badge
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  margin: EdgeInsets.all(isMobile ? 5 : 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AppImage(
                        imageUrl: tool.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (tool.rating >= 4.8 || tool.reviewCount >= 100)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4500), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                          SizedBox(width: 2),
                          Text(
                            'MOST LIKED',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Text Details & Website-style Layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Badge Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tool.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryYellow,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Tool Name
                    Text(
                      tool.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.primaryBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Rating & Location Row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.primaryYellow, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          '${tool.rating}',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.primaryBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${tool.reviewCount})',
                          style: const TextStyle(color: AppTheme.mediumGray, fontSize: 9),
                        ),
                        const Spacer(),
                        const Icon(Icons.location_on_outlined, color: AppTheme.mediumGray, size: 10),
                        Flexible(
                          child: Text(
                            tool.location,
                            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Price & Rent Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rental Price',
                              style: TextStyle(color: AppTheme.mediumGray, fontSize: 8),
                            ),
                            Text(
                              '₹${tool.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                color: AppTheme.primaryYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryYellow.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Rent',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(
      String title, String subtitle, String imageUrl, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AppImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.multiply,
              color: color.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                            color: AppTheme.primaryWhite,
                            fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.primaryWhite)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}