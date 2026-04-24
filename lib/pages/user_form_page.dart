import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _noTelponController =
        TextEditingController(text: widget.user?.noTelpon ?? '+62');
    _alamatController = TextEditingController(text: widget.user?.alamat ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _noTelponController.dispose();
    _alamatController.dispose();
    super.dispose();
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

  // Validasi No Telpon - format +62, max 15 karakter + libphonenumber parse
  String? _validateNoTelpon(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'No. Telpon tidak boleh kosong';
    }
    if (!value.trim().startsWith('+62')) {
      return 'No. Telpon harus diawali dengan +62';
    }
    if (value.trim().length > 15) {
      return 'No. Telpon tidak boleh melebihi 15 karakter';
    }
    if (value.trim().length < 10) {
      return 'No. Telpon minimal 10 karakter (contoh: +628123456)';
    }
    // Cek hanya angka setelah +
    final phoneDigits = value.trim().substring(1);
    if (!RegExp(r'^\d+$').hasMatch(phoneDigits)) {
      return 'No. Telpon hanya boleh berisi angka setelah tanda +';
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
      // parse() adalah top-level function dari flutter_libphonenumber
      final result = await parse(phone, region: 'ID');

      // Jika berhasil di-parse, nomor valid
      if (result['e164'] == null || result['e164'].toString().isEmpty) {
        setState(() {
          _phoneAsyncError =
              'Nomor telepon tidak valid menurut format Indonesia';
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
        _phoneAsyncError = 'Nomor telepon tidak valid menurut format Indonesia';
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

  void _submitForm() async {
    // Reset phone async error dulu
    setState(() {
      _phoneAsyncError = null;
    });

    // Validasi form synchronous dulu
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi async nomor telepon pakai flutter_libphonenumber
    final phoneNumber = _noTelponController.text.trim();
    final isPhoneValid = await _validatePhoneWithLibphonenumber(phoneNumber);

    if (!isPhoneValid) {
      // Re-validate form supaya error muncul di field
      _formKey.currentState!.validate();
      return;
    }

    final user = UserEntity(
      id: isEditing
          ? widget.user!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      noTelpon: _noTelponController.text.trim(),
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

              // Field No Telpon (with libphonenumber validation + auto-format)
              TextFormField(
                controller: _noTelponController,
                decoration: InputDecoration(
                  labelText: 'No. Telpon',
                  hintText: '+628xxxxxxxxxx',
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: _isValidatingPhone
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText:
                      'Format: +62xxx, maks 15 karakter (validasi via libphonenumber)',
                  counterText: '',
                ),
                validator: _validateNoTelpon,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  LibPhonenumberTextFormatter(
                    phoneNumberType: PhoneNumberType.mobile,
                    phoneNumberFormat: PhoneNumberFormat.international,
                    country: CountryWithPhoneCode(
                      phoneCode: '62',
                      countryCode: 'ID',
                      exampleNumberMobileNational: '0812-345-6789',
                      exampleNumberFixedLineNational: '021-234-5678',
                      phoneMaskMobileNational: '0000-000-0000',
                      phoneMaskFixedLineNational: '000-000-0000',
                      exampleNumberMobileInternational: '+62 812-345-6789',
                      exampleNumberFixedLineInternational: '+62 21-234-5678',
                      phoneMaskMobileInternational: '+00 000-000-0000',
                      phoneMaskFixedLineInternational: '+00 00-000-0000',
                      countryName: 'Indonesia',
                    ),
                    inputContainsCountryCode: true,
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
