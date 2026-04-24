import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:pertemuan8/bloc/user_bloc.dart';
import 'package:pertemuan8/bloc/user_event.dart';
import 'package:pertemuan8/domain/entities/user_entity.dart';

class UserFormPage extends StatefulWidget {
  final UserEntity? user;

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _noTelponController;
  late TextEditingController _alamatController;

  bool get isEditing => widget.user != null;

  // Status validasi async untuk nomor telepon
  String? _phoneAsyncError;
  bool _isValidatingPhone = false;

  // Country code picker
  CountryWithPhoneCode? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _noTelponController =
        TextEditingController(text: widget.user?.noTelpon ?? '');
    _alamatController = TextEditingController(text: widget.user?.alamat ?? '');

    // Set default country ke Indonesia
    _initDefaultCountry();
  }

  void _initDefaultCountry() {
    final countries = CountryManager().countries;
    if (countries.isNotEmpty) {
      // Cari Indonesia, kalau tidak ada pakai yang pertama
      _selectedCountry = countries.firstWhere(
        (c) => c.countryCode == 'ID',
        orElse: () => countries.first,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _noTelponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // Tampilkan bottom sheet untuk pilih negara
  void _showCountryPicker() async {
    final countries = CountryManager().countries
      ..sort((a, b) =>
          (a.countryName ?? '').compareTo(b.countryName ?? ''));

    final result = await showModalBottomSheet<CountryWithPhoneCode>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Pilih Kode Negara',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final isSelected =
                          country.countryCode == _selectedCountry?.countryCode;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade200,
                          child: Text(
                            '+${country.phoneCode}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        title: Text(country.countryName ?? country.countryCode),
                        subtitle: Text('+${country.phoneCode}'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Colors.deepPurple)
                            : null,
                        onTap: () => Navigator.pop(context, country),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCountry = result;
      });
    }
  }

  // Validasi Nama
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // Validasi Email
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Validasi No Telpon - max 15 karakter + libphonenumber parse
  String? _validateNoTelpon(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'No. Telpon tidak boleh kosong';
    }

    // Gabungkan kode negara + nomor untuk cek total panjang
    final fullNumber = '+${_selectedCountry?.phoneCode ?? '62'}${value.trim()}';

    if (fullNumber.length > 15) {
      return 'No. Telpon (dengan kode negara) tidak boleh melebihi 15 karakter';
    }
    if (value.trim().length < 4) {
      return 'No. Telpon terlalu pendek';
    }
    // Cek hanya angka
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'No. Telpon hanya boleh berisi angka';
    }
    // Return error dari async validation jika ada
    if (_phoneAsyncError != null) {
      return _phoneAsyncError;
    }
    return null;
  }

  // Validasi async menggunakan flutter_libphonenumber (top-level parse function)
  Future<bool> _validatePhoneWithLibphonenumber(String phone) async {
    setState(() {
      _isValidatingPhone = true;
      _phoneAsyncError = null;
    });
    try {
      final regionCode = _selectedCountry?.countryCode ?? 'ID';
      // parse() adalah top-level function dari flutter_libphonenumber
      final result = await parse(phone, region: regionCode);

      // Jika berhasil di-parse, nomor valid
      if (result['e164'] == null || result['e164'].toString().isEmpty) {
        setState(() {
          _phoneAsyncError = 'Nomor telepon tidak valid untuk negara yang dipilih';
          _isValidatingPhone = false;
        });
        return false;
      }
      setState(() {
        _isValidatingPhone = false;
        _phoneAsyncError = null;
      });
      return true;
    } catch (e) {
      setState(() {
        _phoneAsyncError = 'Nomor telepon tidak valid untuk negara yang dipilih';
        _isValidatingPhone = false;
      });
      return false;
    }
  }

  // Validasi Alamat
  String? _validateAlamat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alamat tidak boleh kosong';
    }
    if (value.trim().length < 5) {
      return 'Alamat minimal 5 karakter';
    }
    return null;
  }

  // Gabungkan kode negara + nomor lokal
  String _getFullPhoneNumber() {
    final code = _selectedCountry?.phoneCode ?? '62';
    final localNumber = _noTelponController.text.trim();
    return '+$code$localNumber';
  }

  void _submitForm() async {
    setState(() {
      _phoneAsyncError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi async nomor telepon pakai flutter_libphonenumber
    final fullPhone = _getFullPhoneNumber();
    final isPhoneValid = await _validatePhoneWithLibphonenumber(fullPhone);

    if (!isPhoneValid) {
      _formKey.currentState!.validate();
      return;
    }

    final user = UserEntity(
      id: isEditing
          ? widget.user!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      noTelpon: _getFullPhoneNumber(), // Simpan dengan kode negara lengkap
      alamat: _alamatController.text.trim(),
    );

    if (isEditing) {
      context.read<UserBloc>().add(UpdateUser(user));
    } else {
      context.read<UserBloc>().add(AddUser(user));
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'User berhasil diperbarui!'
              : 'User berhasil ditambahkan!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit User' : 'Tambah User',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon
              Icon(
                isEditing ? Icons.edit_note : Icons.person_add,
                size: 60,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 8),
              Text(
                isEditing ? 'Edit Data User' : 'Tambah User Baru',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),

              // Field Nama
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama lengkap',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Field Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan alamat email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Field No Telpon dengan country code picker
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol pilih kode negara
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${_selectedCountry?.phoneCode ?? '62'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Input nomor telepon
                  Expanded(
                    child: TextFormField(
                      controller: _noTelponController,
                      decoration: InputDecoration(
                        labelText: 'No. Telpon',
                        hintText: '8123456789',
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: _isValidatingPhone
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Maks 15 karakter total (validasi libphonenumber)',
                        counterText: '',
                      ),
                      validator: _validateNoTelpon,
                      keyboardType: TextInputType.phone,
                      maxLength: 13,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Field Alamat
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Masukkan alamat lengkap',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validateAlamat,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Tombol Submit
              ElevatedButton.icon(
                onPressed: _isValidatingPhone ? null : _submitForm,
                icon: Icon(
                  isEditing ? Icons.save : Icons.add,
                  color: Colors.white,
                ),
                label: Text(
                  isEditing ? 'Simpan Perubahan' : 'Tambah User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
