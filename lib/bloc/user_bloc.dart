import 'package:bloc/bloc.dart';
import 'package:pertemuan8/bloc/user_event.dart';
import 'package:pertemuan8/bloc/user_state.dart';
import 'package:pertemuan8/domain/repository/user_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc(this.userRepository) : super(UserInitial()){
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async{
    emit(UserLoading());
    try{
      final users = await userRepository.getAllUsers();
      emit(UserLoaded(users));
    }catch(e){
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onAddUser(AddUser event, Emitter<UserState> emit) async{
    try{
      await userRepository.addUser(event.user);
      final users = await userRepository.getAllUsers();
      emit(UserLoaded(users));
    }catch(e){
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async{
    try{
      await userRepository.updateUser(event.user);
      final users = await userRepository.getAllUsers();
      emit(UserLoaded(users));
    }catch(e){
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async{
    try{
      await userRepository.deleteUser(event.id);
      final users = await userRepository.getAllUsers();
      emit(UserLoaded(users));
    }catch(e){
      emit(UserError(e.toString()));
    }
  }
}