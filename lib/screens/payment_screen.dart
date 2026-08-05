import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../dummy_data/dummy_data.dart';



class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentScreen({super.key, required this.bookingData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'cash';
  bool _isProcessing = false;
  bool _paymentSuccess = false;

  // ✅ FIX: safe 'is' check — never crashes even if null
  ToolModel? get _tool {
    final raw = widget.bookingData['tool'];
    return raw is ToolModel ? raw : null;
  }

  double get _totalPrice =>
      (widget.bookingData['totalPrice'] as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: graceful error screen if tool is missing
    if (_tool == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: AppTheme.mediumGray.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Booking data missing.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.mediumGray)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back',
                    style: TextStyle(color: AppTheme.primaryYellow)),
              ),
            ],
          ),
        ),
      );
    }

    if (_paymentSuccess) return _buildSuccessScreen();

    final tool = _tool!;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Text('Order Summary',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(context: context),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      tool.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.lightGray,
                        child: const Icon(Icons.error_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tool.name,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_totalPrice.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Payment methods
            Text('Payment Method',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildPaymentMethod(
                'cash',
                'Cash on Delivery 🚚',
                Icons.local_shipping_outlined,
                'Pay cash when you receive the tool at your site / location'),
            const SizedBox(height: 24),

            // Payment details
            Text('Payment Details',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(context: context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRow('Tool Rental Daily Fee',
                      '₹${(_totalPrice * 0.75).toStringAsFixed(0)}'),
                  const SizedBox(height: 12),
                  _buildPriceRow('Service & Delivery Fee', '₹350'),
                  const SizedBox(height: 12),
                  _buildPriceRow('GST / Taxes (18%)',
                      '₹${((_totalPrice * 0.75 + 350) * 0.18).toStringAsFixed(0)}'),
                  const SizedBox(height: 12),
                  _buildPriceRow('Refundable Security Deposit', '₹500'),
                  const Divider(height: 28, thickness: 1),
                  _buildPriceRow(
                    'Total Payable Amount',
                    '₹${_totalPrice.toStringAsFixed(0)}',
                    isBold: true,
                    color: AppTheme.primaryYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryWhite,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlack.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: GradientButton(
            text: _isProcessing
                ? 'Processing Order...'
                : 'Confirm Order (Cash on Delivery)',
            onPressed: _isProcessing
                ? null
                : () async {
                    setState(() => _isProcessing = true);

                    // Credit revenue to Shop Owner Dashboard via SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    final double currentRevenue = prefs.getDouble('shop_owner_total_earnings') ?? 48500.0;
                    final double updatedRevenue = currentRevenue + _totalPrice;
                    await prefs.setDouble('shop_owner_total_earnings', updatedRevenue);

                    // Record real customer booking into SharedPreferences
                    final List<String> customerBookings = prefs.getStringList('customer_real_bookings') ?? [];
                    final newBookingJson = jsonEncode({
                      'id': 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      'status': 'pending',
                      'startDate': DateTime.now().toIso8601String(),
                      'endDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
                      'rentalDays': 3,
                      'totalPrice': _totalPrice,
                      'userName': prefs.getString('userName') ?? DummyData.currentUser.name,
                      'userPhone': DummyData.currentUser.phone,
                      'userAddress': DummyData.currentUser.location,
                      'paymentMethod': 'cash',
                      'tool': {
                        'id': tool.id,
                        'name': tool.name,
                        'category': tool.category,
                        'pricePerDay': tool.pricePerDay,
                        'imageUrl': tool.imageUrl,
                      }
                    });
                    customerBookings.insert(0, newBookingJson);
                    await prefs.setStringList('customer_real_bookings', customerBookings);

                    // Record transaction details
                    final List<String> recentTxns = prefs.getStringList('shop_owner_recent_txns') ?? [];
                    const methodLabel = 'Cash on Delivery';
                    recentTxns.insert(0, '${tool.name}|₹${_totalPrice.toStringAsFixed(0)}|$methodLabel|Just now');
                    await prefs.setStringList('shop_owner_recent_txns', recentTxns);

                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          _isProcessing = false;
                          _paymentSuccess = true;
                        });
                      }
                    });
                  },

            isLoading: _isProcessing,
          ),
        ),
      ),
    );
  }


  Widget _buildPaymentMethod(
      String value, String title, IconData icon, String subtitle) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryYellow.withOpacity(0.1)
              : AppTheme.primaryWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryYellow
                : AppTheme.mediumGray.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlack.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primaryYellow : AppTheme.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppTheme.primaryBlack
                      : AppTheme.mediumGray,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.mediumGray)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) =>
                  setState(() => _selectedPaymentMethod = val!),
              activeColor: AppTheme.primaryYellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? defaultTextColor,
                )),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? defaultTextColor,
                )),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppTheme.accentGreen, size: 80),
              ).animate().scale().fadeIn(),
              const SizedBox(height: 32),
              Text(
                'Payment Successful!',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                'Your booking has been confirmed.\nYou will receive a confirmation shortly.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.mediumGray),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              GradientButton(
                text: 'View Booking',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppTheme.primaryYellow),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back to Home',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: AppTheme.primaryYellow,
                          fontWeight: FontWeight.w600,
                        )),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}