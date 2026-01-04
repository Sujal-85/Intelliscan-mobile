import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/theme/design_system.dart';
import '../../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionComplete;

  const SubscriptionScreen({super.key, this.onSubscriptionComplete});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  late Razorpay _razorpay;
  bool _isLoading = true;
  Map<String, dynamic> _currentStatus = {};
  String? _pendingPlan;

  // Use the key found in backend/.env
  static const String _razorpayKeyId = 'rzp_test_Rv1OkXEvoNQ9v69c';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    final status = await _subscriptionService.getSubscriptionStatus();
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _startPayment(String planName, int amount) async {
    setState(() => _isLoading = true);

    // 1. Create order on backend
    final order = await _subscriptionService.createOrder(planName);

    if (order == null || !order.containsKey('id')) {
      Fluttertoast.showToast(msg: "Failed to initiate payment");
      setState(() => _isLoading = false);
      return;
    }

    // 2. Open Razorpay Checkout
    var options = {
      'key': _razorpayKeyId,
      'amount': order['amount'],
      'currency': 'INR',
      'name': 'IntelliScan',
      'description': '$planName Plan',
      'order_id': order['id'],
      'prefill': {
        'contact': '9123456789', // Ideally fetch from user profile
        'email': 'user@example.com', // Ideally fetch from user profile
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingPlan == null) return;

    final success = await _subscriptionService.verifyPayment(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
      planName: _pendingPlan!,
    );

    if (success) {
      Fluttertoast.showToast(msg: "Subscription upgraded successfully!");
      _fetchStatus();
      if (widget.onSubscriptionComplete != null) {
        widget.onSubscriptionComplete!();
      }
    } else {
      Fluttertoast.showToast(msg: "Payment verification failed");
    }
    setState(() => _isLoading = false);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment failed: ${response.message}");
    setState(() => _isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
    setState(() => _isLoading = false);
  }

  void _onUpgradeTap(String planName, int amount) {
    _pendingPlan = planName;
    _startPayment(planName, amount);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = _currentStatus['plan'] ?? 'starter';
    final credits = _currentStatus['credits'] ?? 0;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                decoration: const BoxDecoration(
                  gradient: DesignSystem.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Subscriptions',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Current Status Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                "CURRENT PLAN",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentPlan.toString().toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Column(
                            children: [
                              Text(
                                "AVAILABLE CREDITS",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$credits",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        _buildPlanCard(
                          title: 'Starter',
                          price: 'Free',
                          period: '/forever',
                          features: [
                            '100 Credits',
                            'Basic OCR',
                            'Limited Access',
                          ],
                          isCurrent: currentPlan == 'starter',
                          color: Colors.blueGrey,
                          onTap: null,
                        ),
                        const SizedBox(height: 24),
                        _buildPlanCard(
                          title: 'Pro',
                          price: '₹799',
                          period: '/month',
                          features: [
                            '3000 Credits / month',
                            'Unlimited OCR',
                            'Advanced PDF Tools',
                            'No Ads',
                            'Priority Support',
                          ],
                          isCurrent: currentPlan == 'pro',
                          isBestValue: true,
                          color: DesignSystem.primaryPurple,
                          onTap: () => _onUpgradeTap('pro', 79900),
                        ),
                        const SizedBox(height: 24),
                        _buildPlanCard(
                          title: 'Premium',
                          price: '₹999',
                          period: '/month',
                          features: [
                            '5000 Credits / month',
                            'All Pro Features',
                            'Advanced AI Models',
                            'VIP Support',
                            'Team Management',
                          ],
                          isCurrent: currentPlan == 'premium',
                          color: Colors.orange,
                          onTap: () => _onUpgradeTap('premium', 99900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isCurrent,
    required Color color,
    bool isBestValue = false,
    VoidCallback? onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DesignSystem.surfaceColor(context),
            borderRadius: BorderRadius.circular(24),
            border: isCurrent
                ? Border.all(color: color, width: 2)
                : Border.all(color: DesignSystem.glassBorder),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textColor(context),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Active',
                        style: GoogleFonts.outfit(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      period,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: DesignSystem.secondaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrent ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey[200],
                    elevation: 0,
                  ),
                  child: Text(
                    isCurrent ? 'Current Plan' : 'Upgrade Now',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isBestValue && !isCurrent)
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.primaryPurple.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Best Value',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
