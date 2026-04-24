import 'package:pertemuan8/data/models/user_model.dart';
import 'package:pertemuan8/domain/entities/user_entity.dart';
import 'package:pertemuan8/domain/repository/user_repository.dart';
import 'package:pertemuan8/helper/database_helper.dart';

class UserRepositoryImpl implements UserRepository{
  final DatabaseHelper dbHelper;
  UserRepositoryImpl(this.dbHelper);

  @override
  Future<List<UserEntity>> getAllUsers() async{
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((userMap) => UserModel.fromMap(userMap)).toList();
  }

  @override
  Future<void> addUser(UserEntity user) async{
    final db = await dbHelper.database;
    final userModel = UserModel(
      id: user.id, 
      name: user.name, 
      email: user.email,
      noTelpon: user.noTelpon,
      alamat: user.alamat
    );
    await db.insert('users', userModel.toMap());
  }

  @override
  Future<void> deleteUser(String id) async{
    final db = await dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateUser(UserEntity user) async{
    final db = await dbHelper.database;
    final userModel = UserModel(
      id: user.id, 
      name: user.name, 
      email: user.email,
      noTelpon: user.noTelpon,
      alamat: user.alamat
    );
    await db.update(
      'users', 
      userModel.toMap(), 
      where: 'id = ?', 
      whereArgs: [user.id]
    );
  }
}