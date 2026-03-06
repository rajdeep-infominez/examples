import 'package:flutter/material.dart';
import 'package:glomopay_sdk/glomopay_sdk.dart';


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
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();
  Map<String, dynamic>? _paymentResult;



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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startCheckout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Start Checkout'),
              ),
              const SizedBox(height: 24),
              if (_paymentResult != null) ...[
                const Divider(),
                const Text('Last Payment Result:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _paymentResult!['status'] == 'success'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    border: Border.all(
                        color: _paymentResult!['status'] == 'success'
                            ? Colors.green
                            : Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${_paymentResult!['status'].toUpperCase()}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _paymentResult!['status'] == 'success'
                                  ? Colors.green
                                  : Colors.red)),
                      const SizedBox(height: 4),
                      Text('Order ID: ${_paymentResult!['payload'].orderId}'),
                      if (_paymentResult!['payload'].paymentId != null)
                        Text(
                            'Payment ID: ${_paymentResult!['payload'].paymentId}'),
                      const SizedBox(height: 8),
                      const Text('Raw Response:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          _paymentResult!['payload'].rawResponse?.toString() ??
                              'N/A',
                          style: const TextStyle(
                              fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
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
