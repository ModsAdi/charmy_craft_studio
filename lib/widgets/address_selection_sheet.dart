// lib/widgets/address_selection_sheet.dart

import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/screens/profile/add_edit_address_screen.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider to fetch addresses for the current user
final userAddressesProvider = StreamProvider.autoDispose<List<Address>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.read(firestoreServiceProvider).getAddresses(user.uid);
});

class AddressSelectionSheet extends ConsumerWidget {
  final Function(Address selectedAddress) onAddressSelected;

  const AddressSelectionSheet({super.key, required this.onAddressSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(userAddressesProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a Shipping Address',
                style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              Expanded(
                child: addressesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return const Center(child: Text('No addresses found. Please add one.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(address.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${address.flatHouseNo}, ${address.areaStreet}, ${address.townCity} - ${address.pincode}'),
                            trailing: address.isDefault
                                ? Chip(label: const Text('Default'), padding: EdgeInsets.zero)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(); // Close the sheet
                              onAddressSelected(address); // Pass selected address back
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add New Address'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: theme.colorScheme.secondary),
                      foregroundColor: theme.colorScheme.secondary
                  ),
                  onPressed: () {
                    // We pop the sheet first, then push the new screen
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditAddressScreen()));
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}