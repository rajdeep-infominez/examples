import 'package:flutter/material.dart';
import 'package:glomopay_sdk/glomopay_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlomoPay SDK Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EE)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _publicKeyController = TextEditingController(text: 'test_6973157evRSvoAfY');
  final TextEditingController _orderIdController = TextEditingController();
  bool _devMode = true;
  bool _isLoading = false;
  Map<String, dynamic>? _paymentResult;

  final String _authToken = 'Bearer eyJhbGciOiJSUzI1NiJ9.eyJlbnYiOiJzYW5kYm94IiwiZXhwIjo0OTI0ODIzNDIyLCJpYXQiOjE3NjkxNDk4MjIsImF1ZCI6InNhbmRib3gtYXBpLmdsb21vcGF5LmNvbSIsImlzcyI6InNhbmRib3gtYXBpLmdsb21vcGF5LmNvbSIsInN1YiI6Im1lcmNoXzY5NzMxNTdiRkdyR2oiLCJqdGkiOiJjNThhYmJmOC04NTA0LTRmN2ItYjk4Yy0xNzQ2ZjY5ZTg2YmMifQ.yGpma_7aZiiSQq66rFNQCybXta9igZ0Ypw3dGnZEkB_PuB9p7wwVjyukUOf8hMyQzvIZno3_0NFv5SYIV0QNlbC9-Pimfx77kQkPyxu1TCtW6Avwj4AscfrVYNFMAxPXwHe1WCYm0DG8H2RBB3dBycDvYLW363ZDMwsdzjaXDVnJJBffFGkfbjUEtCStIT6hNo-ILXAE1-C3yPnQDmet12WDAaBv9CNSP1IpHeuM5LGVRJ1dEBOR-FJ68ZXfY4_3APP4w2uHExI8fkl0_UyJKsyfsn9rViNX9BaVIqkgwUzS3pkczjF8B4tshjektx9bbxx2sDs0Rc2J5Mq8RBAryQ';

  Future<void> _createStandardOrder() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://api.glomopay.com/api/v1/orders'),
        headers: {
          'Authorization': _authToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "customer_id": "cust_698092439M9Nb",
          "currency": "USD",
          "amount": 1000,
          "purpose_code": "P1401",
          "invoice_number": "RG12FF590",
          "invoice_description": "First Payment",
          "reference_number": "R0002"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _orderIdController.text = data['id'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Standard Order Created!')),
        );
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
      }
    } finally {
      if (mounted) {
         setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _createQuote() async {
    final response = await http.post(
      Uri.parse('https://api.glomopay.com/api/v1/lrs/quotes'),
      headers: {
        'Authorization': _authToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bank_code": "hdfc",
        "source_amount": 100000,
        "source_currency": "USD",
        "target_currency": "INR"
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create quote: ${response.body}');
    }
  }

  Future<void> _createLrsOrder() async {
     setState(() => _isLoading = true);
    try {
      // 1. Get a fresh Quote
      final quoteData = await _createQuote();
      final quoteId = quoteData['id'];
      final expiresAt = quoteData['expires_at'];
      
      debugPrint('Quote Created: $quoteId, Expires: $expiresAt');
      
      // Optional: Show intermediate status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote: $quoteId (Exp: $expiresAt)')),
      );

      // 2. Create Order with the fresh Quote ID
      final requestBody = jsonEncode({
          "customer_id": "cust_697b0519Cy9s6",
          "currency": "USD",
          "amount": 100000,
          "purpose_code": "P1401",
          "invoice_number": "RG12FF590",
          "invoice_description": "First Payment",
          "reference_number": "R0002",
          "lrs": {
              "lrs_quote_id": quoteId,
              "remittance_information": "brokerid",
              "bank_account_id": "acclrs_697c4977dgVkU"
          }
      });
      
      debugPrint('Creating LRS Order with body: $requestBody');

      final response = await http.post(
        Uri.parse('https://api.glomopay.com/api/v1/orders'),
        headers: {
          'Authorization': _authToken,
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _orderIdController.text = data['id'];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order Created: ${data['id']}')),
          );
        }
      } else {
        throw Exception('Failed to create LRS order: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
         showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                title: const Text('Error Creating Order'),
                content: SingleChildScrollView(child: Text(e.toString())),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            )
         );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCheckout() async {
    final publicKey = _publicKeyController.text.trim();
    final orderId = _orderIdController.text.trim();

    if (publicKey.isEmpty || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Public Key and Order ID')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          config: GlomoPayConfig(
            publicKey: publicKey,
            orderId: orderId,
            devMode: _devMode,
          ),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
       setState(() {
          _paymentResult = result;
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GlomoPay SDK Tester'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _publicKeyController,
                decoration: const InputDecoration(
                  labelText: 'Public Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  labelText: 'Order ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Dev Mode'),
                value: _devMode,
                onChanged: (val) => setState(() => _devMode = val),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createStandardOrder,
                        child: const Text('Create Standard Order'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createLrsOrder,
                        child: const Text('Create LRS Order'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startCheckout,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Start Checkout'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint('🧪 Testing GlomoPay SDK Sentry integration...');
                    
                    // Trigger SDK validation error which will:
                    // 1. Initialize the SDK's ErrorTracker (Sentry)
                    // 2. Send an error to the SDK's Sentry project
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          config: GlomoPayConfig(
                            publicKey: 'invalid_test_key', // Invalid key to trigger validation error
                            orderId: 'test_order_123',
                            devMode: true,
                          ),
                        ),
                      ),
                    );
                    
                    debugPrint('🎉 SDK Sentry test completed! Check console for [GlomoPay] [Sentry] logs');
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ SDK Sentry tested! Check console for SDK logs.'),
                        backgroundColor: Colors.deepPurple,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🧪 Test SDK Sentry (Validation Error)'),
                ),
                const SizedBox(height: 24),
                if (_paymentResult != null) ...[
                  const Divider(),
                  const Text('Last Payment Result:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentResult!['status'] == 'success' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      border: Border.all(color: _paymentResult!['status'] == 'success' ? Colors.green : Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${_paymentResult!['status'].toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: _paymentResult!['status'] == 'success' ? Colors.green : Colors.red)),
                         const SizedBox(height: 4),
                        Text('Order ID: ${_paymentResult!['payload'].orderId}'),
                         if (_paymentResult!['payload'].paymentId != null)
                           Text('Payment ID: ${_paymentResult!['payload'].paymentId}'),
                         const SizedBox(height: 8),
                         const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.w600)),
                         Text(_paymentResult!['payload'].rawResponse?.toString() ?? 'N/A', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  final GlomoPayConfig config;

  const CheckoutPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: GlomoPayCheckout(
        config: config,
        onPaymentSuccess: (payload) {
          debugPrint('Payment Success: $payload');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful')),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context, {'status': 'success', 'payload': payload});
          }
        },
        onPaymentFailure: (payload) {
          debugPrint('Payment Failure: $payload');
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Failed')),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context, {'status': 'failure', 'payload': payload});
          }
        },
        onSdkError: (errors) {
          debugPrint('SDK Error: $errors');
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SDK Error: ${errors.first.message}')),
          );
        },
        onConnectionError: (error) {
           debugPrint('Connection Error: $error');
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection Error: $error')),
          );
        },
        onEvent: (event, data) {
           debugPrint('Event: $event, Data: $data');
        },
      ),
    );
  }
}
