import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../models/tool_model.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/vendor_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_image.dart';
import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBanner = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;

  List<ToolModel> get _filteredTools {
    if (_searchQuery.isEmpty) return DummyData.tools;
    return DummyData.tools.where((tool) {
      return tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Search bar with live results below
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

                    // ✅ Inline search results dropdown
                    if (_showSearchResults) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _filteredTools.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        color: AppTheme.mediumGray
                                            .withOpacity(0.5),
                                        size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      'No results for "$_searchQuery"',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: AppTheme.mediumGray),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredTools.length > 5
                                    ? 5
                                    : _filteredTools.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color:
                                      AppTheme.mediumGray.withOpacity(0.15),
                                ),
                                itemBuilder: (context, index) {
                                  final tool = _filteredTools[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: AppImage(
                                        imageUrl: tool.imageUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(
                                      tool.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      tool.category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppTheme.mediumGray),
                                    ),
                                    trailing: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFFF8C00)
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        '₹${tool.pricePerDay}/day',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      // ✅ Navigate to booking screen
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _showSearchResults = false;
                                      });
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingScreen(tool: tool),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      // ✅ Show all results button
                      if (_filteredTools.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/categories');
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFF8C00)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'See all ${_filteredTools.length} results',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
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
                                  child: const Icon(Icons.attach_money,
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
                          'assets/images/download (1).jpg',
                          AppTheme.primaryYellow,
                        ),
                        _buildBanner(
                          'New Tools Added',
                          'Check out our latest equipment',
                          'assets/images/download.jpg',
                          AppTheme.accentBlue,
                        ),
                        _buildBanner(
                          'Free Delivery',
                          'On orders above ₹8,300',
                          'assets/images/download (5).jpg',
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

                    // Popular Tools
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
                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: DummyData.tools.length,
                      itemBuilder: (context, index) {
                        final tool = DummyData.tools[index];
                        return _buildToolCard(tool);
                      },
                    ),
                    const SizedBox(height: 24),

                    _gradientText('Featured Vendors',
                        Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),

                    ...DummyData.vendors.map((vendor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VendorCard(vendor: vendor, onTap: () {}),
                      );
                    }).toList(),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _gradientText('Recent Reviews',
                            Theme.of(context).textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {},
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
                                        Text(review.userName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: AppTheme.primaryYellow,
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text(review.rating.toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
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
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 100),
                  ],
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingScreen(tool: tool),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AppImage(
                  imageUrl: tool.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tool.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tool.category,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.mediumGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                          ).createShader(bounds),
                          child: Text(
                            '₹${tool.pricePerDay}/day',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppTheme.primaryYellow, size: 14),
                            const SizedBox(width: 2),
                            Text(tool.rating.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
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