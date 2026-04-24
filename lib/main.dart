import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:pertemuan8/bloc/user_bloc.dart';
import 'package:pertemuan8/bloc/user_event.dart';
import 'package:pertemuan8/data/repositories/user_repository_impl.dart';
import 'package:pertemuan8/helper/database_helper.dart';
import 'package:pertemuan8/pages/user_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // Inisialisasi flutter_libphonenumber
  final databaseHelper = DatabaseHelper();
  final userRepository = UserRepositoryImpl(databaseHelper);
  runApp( MyApp(repository: userRepository));
}

class MyApp extends StatelessWidget {
  final UserRepositoryImpl repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc(repository)..add(LoadUsers()),
      child: MaterialApp(
        title: 'SQLite CRUD - Activity 6',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const UserListPage(),
      ),
    );
  }
}
