import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentScreen({super.key, required this.bookingData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
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
              decoration: AppTheme.cardDecoration(),
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
                'card', 'Credit/Debit Card', Icons.credit_card,
                '•••• •••• •••• 4242'),
            const SizedBox(height: 12),
            _buildPaymentMethod(
                'upi', 'UPI', Icons.account_balance, 'Select UPI App'),
            const SizedBox(height: 12),
            _buildPaymentMethod('netbanking', 'Net Banking',
                Icons.account_balance_wallet, 'Select Bank'),
            const SizedBox(height: 24),
            // Card details
            if (_selectedPaymentMethod == 'card') ...[
              Text('Card Details',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        hintText: '•••• •••• •••• ••••',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date',
                              hintText: 'MM/YY',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '•••',
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name',
                        hintText: 'Enter name on card',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Payment details
            Text('Payment Details',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal',
                      '₹${(_totalPrice - 830).toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildPriceRow('Service Fee', '₹830'),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total Amount',
                    '₹${_totalPrice.toStringAsFixed(0)}',
                    isBold: true,
                    color: AppTheme.primaryYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
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
                ? 'Processing...'
                : 'Pay ₹${_totalPrice.toStringAsFixed(0)}',
            onPressed: _isProcessing
                ? null
                : () {
                    setState(() => _isProcessing = true);
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal,
                )),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w600,
                  color: color,
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