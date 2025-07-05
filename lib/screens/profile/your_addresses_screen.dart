// lib/screens/profile/your_addresses_screen.dart
import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/screens/profile/add_edit_address_screen.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// New provider to stream addresses
final addressesProvider = StreamProvider<List<Address>>((ref) {
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
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (addresses) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: addresses.length + 1, // +1 for the "Add Address" button
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a new address'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AddEditAddressScreen(),
                      ));
                    },
                  ),
                );
              }
              final address = addresses[index - 1];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${address.flatHouseNo}, ${address.areaStreet}'),
                      Text('${address.townCity}, ${address.state} ${address.pincode}'),
                      Text(address.country),
                      const SizedBox(height: 8),
                      Text('Phone number: ${address.mobileNumber}'),
                      const Divider(),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AddEditAddressScreen(address: address),
                              ));
                            },
                            child: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final user = ref.read(authStateChangesProvider).value;
                              if (user != null) {
                                await ref.read(firestoreServiceProvider).deleteAddress(user.uid, address.id!);
                              }
                            },
                            child: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}