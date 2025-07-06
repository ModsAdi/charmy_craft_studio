import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/screens/profile/add_edit_address_screen.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider to stream addresses from Firestore
final addressesProvider = StreamProvider.autoDispose<List<Address>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.read(firestoreServiceProvider).getAddresses(user.uid);
});

class YourAddressesScreen extends ConsumerWidget {
  const YourAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Addresses', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error fetching addresses: $err')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildAddressList(context, addresses);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddScreen(context),
        label: const Text('Add New Address'),
        icon: const Icon(Icons.add_location_alt_outlined),
        // ** FIX: Use the app's accent color for the FAB **
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _navigateToAddScreen(BuildContext context, {Address? address}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'No Addresses Found',
              style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "Add New Address" button below to get started.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context, List<Address> addresses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 96), // Extra padding for FAB
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _AddressCard(address: address);
      },
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final Address address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDefault = address.isDefault;
    final accentColor = theme.colorScheme.secondary;

    return Card(
      elevation: isDefault ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDefault
            ? BorderSide(color: accentColor, width: 1.5)
            : BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_work_outlined, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.nickname?.isNotEmpty == true ? address.nickname! : address.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (address.nickname?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            address.fullName,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isDefault)
                // ** FIX: Correctly styled chip for readability **
                  Chip(
                    label: const Text('Default', style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: accentColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: accentColor),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(
              '${address.flatHouseNo}, ${address.areaStreet}',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
            Text(
              '${address.townCity}, ${address.state} - ${address.pincode}',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
            if(address.landmark.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Landmark: ${address.landmark}',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Mobile: ${address.mobileNumber}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ** FIX: Correctly styled buttons **
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddEditAddressScreen(address: address),
                    ));
                  },
                  child: Text('Edit', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _confirmDelete(context, ref),
                  child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final user = ref.read(authStateChangesProvider).value;
              if (user != null && address.id != null) {
                await ref.read(firestoreServiceProvider).deleteAddress(user.uid, address.id!);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}