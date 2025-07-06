import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _houseController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _cityController;
  bool _isDefault = false;

  String _selectedState = 'West Bengal';
  final List<String> _states = ['West Bengal', 'Maharashtra', 'Karnataka', 'Delhi', 'Uttar Pradesh', 'Tamil Nadu', 'Gujarat'];

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _nicknameController = TextEditingController(text: address?.nickname ?? '');
    _nameController = TextEditingController(text: address?.fullName ?? '');
    _mobileController = TextEditingController(text: address?.mobileNumber ?? '');
    _houseController = TextEditingController(text: address?.flatHouseNo ?? '');
    _areaController = TextEditingController(text: address?.areaStreet ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');
    _pincodeController = TextEditingController(text: address?.pincode ?? '');
    _cityController = TextEditingController(text: address?.townCity ?? '');
    if (address != null) {
      _selectedState = address.state;
      _isDefault = address.isDefault;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submitAddress() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to save an address.'))
        );
        return;
      }

      final newAddress = Address(
        id: widget.address?.id,
        nickname: _nicknameController.text.trim(),
        country: 'India',
        fullName: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        flatHouseNo: _houseController.text.trim(),
        areaStreet: _areaController.text.trim(),
        landmark: _landmarkController.text.trim(),
        pincode: _pincodeController.text.trim(),
        townCity: _cityController.text.trim(),
        state: _selectedState,
        isDefault: _isDefault,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      try {
        if (widget.address == null) {
          await firestoreService.addAddress(user.uid, newAddress);
        } else {
          await firestoreService.updateAddress(user.uid, newAddress);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving address: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add a new address' : 'Edit address', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildTextField(_nicknameController, 'Address Nickname (e.g., Home, Work)', Icons.label_outline, isRequired: false),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Full name (First and Last name)', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_mobileController, 'Mobile number', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(_houseController, 'Flat, House no., Building, Apartment', Icons.location_city_outlined),
            const SizedBox(height: 16),
            _buildTextField(_areaController, 'Area, Street, Sector, Village', Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField(_landmarkController, 'Landmark', Icons.flag_outlined, isRequired: false),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTextField(_pincodeController, 'Pincode', Icons.pin_drop_outlined, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_cityController, 'Town/City', Icons.business_outlined)),
              ],
            ),
            const SizedBox(height: 16),
            // ++ THIS IS THE FIX ++
            DropdownButtonFormField<String>(
              value: _selectedState,
              items: _states.map((String state) {
                return DropdownMenuItem<String>(value: state, child: Text(state));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedState = newValue!;
                });
              },
              decoration: InputDecoration(
                // The prefixIcon has been removed to prevent overflow
                labelText: 'State',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
            // ++ END OF FIX ++
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set as default address'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              secondary: Icon(Icons.star_outline, color: theme.colorScheme.secondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitAddress,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            widget.address == null ? 'Add This Address' : 'Save Changes',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(TextEditingController controller, String label, IconData icon, {bool isRequired = true, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}