// lib/screens/profile/add_edit_address_screen.dart
import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address; // Pass an address to edit it
  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _houseController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _cityController;

  String _selectedState = 'West Bengal'; // Example state
  final List<String> _states = ['West Bengal', 'Maharashtra', 'Karnataka', 'Delhi'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.fullName);
    _mobileController = TextEditingController(text: widget.address?.mobileNumber);
    _houseController = TextEditingController(text: widget.address?.flatHouseNo);
    _areaController = TextEditingController(text: widget.address?.areaStreet);
    _landmarkController = TextEditingController(text: widget.address?.landmark);
    _pincodeController = TextEditingController(text: widget.address?.pincode);
    _cityController = TextEditingController(text: widget.address?.townCity);
    if (widget.address != null) {
      _selectedState = widget.address!.state;
    }
  }

  @override
  void dispose() {
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
      if (user == null) return;

      final newAddress = Address(
        id: widget.address?.id,
        country: 'India',
        fullName: _nameController.text,
        mobileNumber: _mobileController.text,
        flatHouseNo: _houseController.text,
        areaStreet: _areaController.text,
        landmark: _landmarkController.text,
        pincode: _pincodeController.text,
        townCity: _cityController.text,
        state: _selectedState,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      if (widget.address == null) {
        await firestoreService.addAddress(user.uid, newAddress);
      } else {
        await firestoreService.updateAddress(user.uid, newAddress);
      }
      if(mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add a new address' : 'Edit address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(_nameController, 'Full name (First and Last name)'),
            const SizedBox(height: 12),
            _buildTextField(_mobileController, 'Mobile number', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(_houseController, 'Flat, House no., Building, Company, Apartment'),
            const SizedBox(height: 12),
            _buildTextField(_areaController, 'Area, Street, Sector, Village'),
            const SizedBox(height: 12),
            _buildTextField(_landmarkController, 'Landmark', isRequired: false),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(_pincodeController, 'Pincode', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_cityController, 'Town/City')),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedState,
              items: _states.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedState = newValue!;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitAddress,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add address'),
            )
          ],
        ),
      ),
    );
  }

  TextFormField _buildTextField(TextEditingController controller, String label, {bool isRequired = true, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }
}