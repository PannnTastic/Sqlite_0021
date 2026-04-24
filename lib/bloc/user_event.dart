import 'package:pertemuan8/domain/entities/user_entity.dart';

abstract class UserEvent {}
class LoadUsers extends UserEvent{}
class AddUser extends UserEvent{
  final UserEntity user; 
  AddUser(this.user);
}
class UpdateUser extends UserEvent{
  final UserEntity user; 
  UpdateUser(this.user);
}
class DeleteUser extends UserEvent{
  final String id; 
  DeleteUser(this.id);
}
