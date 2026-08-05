import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/app_image.dart';
import '../widgets/dark_location_map.dart';
import '../config/api_config.dart';
import '../dummy_data/dummy_data.dart';
import 'payment_screen.dart';







class BookingScreen extends StatefulWidget {
  final ToolModel tool;

  const BookingScreen({super.key, required this.tool});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int _rentalDays = 1;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  final _paymentDetailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final totalPrice = _rentalDays * widget.tool.pricePerDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Tool'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Tool summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppImage(
                      imageUrl: widget.tool.imageUrl,
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tool.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.tool.category,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${widget.tool.pricePerDay.toStringAsFixed(0)}/day',
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
            Text(
              'Your Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon: const Icon(Icons.person, color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.primaryWhite,
                    ),
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address',
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.primaryWhite,
                    ),
                    maxLines: 2,
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon: const Icon(Icons.phone, color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppTheme.primaryWhite,
                    ),
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Rental Period',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Calendar
            Container(
              decoration: AppTheme.cardDecoration(),
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _selectedStartDate ?? DateTime.now(),
                calendarFormat: CalendarFormat.month,
                rangeSelectionMode: RangeSelectionMode.enforced,
                rangeStartDay: _selectedStartDate,
                rangeEndDay: _selectedEndDate,
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _selectedStartDate = start;
                    _selectedEndDate = end;
                    if (start != null && end != null) {
                      _rentalDays = end.difference(start).inDays + 1;
                    }
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppTheme.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppTheme.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor:
                      AppTheme.primaryYellow.withOpacity(0.2),
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(color: Colors.black87),
                  weekendTextStyle: const TextStyle(color: Colors.black87),
                  selectedTextStyle: const TextStyle(color: Colors.black87),
                  todayTextStyle: const TextStyle(color: Colors.black87),
                  withinRangeTextStyle: const TextStyle(color: Colors.black87),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ) ?? const TextStyle(color: Colors.black87),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black87),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selected dates display
            if (_selectedStartDate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text('Start Date',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedStartDate!),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text('End Date',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedEndDate != null
                          ? DateFormat('MMM dd, yyyy')
                              .format(_selectedEndDate!)
                          : 'Select end date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text('Rental Duration',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_rentalDays day${_rentalDays > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Live Location & Equipment Delivery Map
            Text(
              'Equipment Delivery & Shop Location Map',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const DarkLocationMap(
              height: 280,
              showCategoryFilter: true,
              showLegend: true,
            ),
            const SizedBox(height: 24),

            Text(
              'Price Breakdown',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(context: context),
              child: Column(
                children: [
                  _buildPriceRow('Daily Rate',
                      '₹${widget.tool.pricePerDay.toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildPriceRow('Rental Days', '$_rentalDays'),
                  const Divider(height: 24),
                  _buildPriceRow(
                      'Subtotal', '₹${totalPrice.toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  _buildPriceRow('Service Fee', '₹830'),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total',
                    '₹${(totalPrice + 830).toStringAsFixed(0)}',
                    isBold: true,
                    color: AppTheme.primaryYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(context: context),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery 🚚', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Pay cash when you receive the tool at your site / location', style: TextStyle(color: Colors.black54)),
                    value: 'cash',
                    groupValue: 'cash',
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = 'cash';
                      });
                    },
                    activeColor: AppTheme.primaryYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
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
            text: 'Proceed to Payment',
            onPressed: _selectedStartDate != null && _selectedEndDate != null
                ? () async {
                    if (_formKey.currentState!.validate()) {
                      // Send booking data to backend
                      try {
                        final response = await http.post(
                          Uri.parse(ApiConfig.bookingsUrl),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'userId': int.tryParse(DummyData.currentUser.id) ?? 1,
                            'tool': {
                              'id': widget.tool.id,
                              'name': widget.tool.name,
                              'category': widget.tool.category,
                              'pricePerDay': widget.tool.pricePerDay,
                              'imageUrl': widget.tool.imageUrl,
                            },
                            'totalPrice': (totalPrice + 830).toDouble(),
                            'startDate': _selectedStartDate!.toIso8601String(),
                            'endDate': _selectedEndDate!.toIso8601String(),
                            'rentalDays': _rentalDays,
                            'userName': _nameController.text,
                            'userAddress': _addressController.text,
                            'userPhone': _phoneController.text,
                            'paymentMethod': _selectedPaymentMethod,
                            'paymentDetails': _paymentDetailsController.text,
                          }),
                        );

                        if (response.statusCode == 201) {
                          print('Booking saved to backend successfully');
                        } else {
                          print('Failed to save booking to backend');
                        }
                      } catch (error) {
                        print('Error saving booking to backend: $error');
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            bookingData: {
                              'tool': widget.tool,
                              'totalPrice': (totalPrice + 830).toDouble(),
                              'startDate': _selectedStartDate,
                              'endDate': _selectedEndDate,
                              'rentalDays': _rentalDays,
                              'userName': _nameController.text,
                              'userAddress': _addressController.text,
                              'userPhone': _phoneController.text,
                            },
                          ),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: defaultColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color ?? defaultColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}