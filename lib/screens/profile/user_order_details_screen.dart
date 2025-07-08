import 'package:charmy_craft_studio/models/order.dart' as my_order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UserOrderDetailsScreen extends StatelessWidget {
  final my_order.Order order;
  const UserOrderDetailsScreen({super.key, required this.order});

  Future<void> _launchUrl(String urlString) async {
    if (!urlString.startsWith('http')) {
      urlString = 'https://$urlString';
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatusTracker(context), // Pass context
          const SizedBox(height: 24),
          _buildInfoCard(
            icon: Icons.receipt_long_outlined,
            title: 'Order Summary',
            children: [
              _buildInfoRow('Order ID:', '#${order.id.substring(0, 12)}...'),
              _buildInfoRow('Placed on:', DateFormat.yMMMMd().format(order.orderPlacementDate)),
              _buildInfoRow('Total Value:', '₹${order.totalValue.toStringAsFixed(2)}', isBold: true),
            ],
          ),
          if (order.deliveryMode != null && order.deliveryMode!.isNotEmpty)
            _buildInfoCard(
              icon: Icons.local_shipping_outlined,
              title: 'Shipment Details',
              children: [
                _buildInfoRow('Shipped Via:', order.deliveryMode!),
                if (order.trackingLink != null && order.trackingLink!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.track_changes_rounded),
                        label: const Text('Track Your Order'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _launchUrl(order.trackingLink!),
                      ),
                    ),
                  ),
                if (order.trackingDetails != null && order.trackingDetails!.isNotEmpty)
                  ...order.trackingDetails!.entries.map((entry) {
                    if (entry.value.toString().isEmpty) return const SizedBox.shrink();
                    return _buildCopyableRow(context, entry.key, entry.value.toString());
                  }),
                if (order.specialNote != null && order.specialNote!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Note from Seller:', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200)
                    ),
                    child: Text(order.specialNote!, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                ]
              ],
            ),
          _buildInfoCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Items in this Order (${order.items.length})',
            children: order.items.map((item) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: item.imageUrl.isNotEmpty ? Image.network(item.imageUrl, width: 50, fit: BoxFit.cover,) : const Icon(Icons.image_not_supported),
              title: Text(item.title),
              trailing: Text('₹${item.price.toStringAsFixed(0)} x ${item.quantity}'),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ++ UPDATED WIDGET ++
  Widget _buildStatusTracker(BuildContext context) {
    // 1. Handle 'Cancelled' status separately for a clearer UI
    if (order.status == 'Cancelled') {
      return Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 16),
              Text(
                'Order Cancelled',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Correctly handle the linear progress for other statuses
    final statuses = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];
    int currentStatusIndex = statuses.indexOf(order.status);
    if (currentStatusIndex == -1) currentStatusIndex = 0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        child: Row(
          children: List.generate(statuses.length, (index) {
            // 3. Updated logic for completion and active state
            final isCompleted = index < currentStatusIndex;
            final isActive = index == currentStatusIndex;

            IconData iconData;
            Color iconColor;

            if (isCompleted) {
              iconData = Icons.check_circle;
              iconColor = Colors.green.shade600;
            } else if (isActive) {
              iconData = Icons.radio_button_checked;
              iconColor = Theme.of(context).colorScheme.secondary;
            } else {
              iconData = Icons.radio_button_unchecked;
              iconColor = Colors.grey.shade300;
            }

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, color: iconColor, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    statuses[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Colors.black : Colors.grey.shade600,
                        fontSize: 13
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20, color: Colors.grey,),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
              );
            },
            splashRadius: 20,
            tooltip: 'Copy',
          )
        ],
      ),
    );
  }
}