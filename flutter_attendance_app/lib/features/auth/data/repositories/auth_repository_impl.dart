import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/config/app_config.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> login(String username, String password) async {
    final user = await remoteDataSource.login(username, password);
    
    // Save user data locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userDataKey, json.encode(user.toJson()));
    
    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.userDataKey);
    await prefs.remove(AppConfig.userTokenKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConfig.userDataKey);
    
    if (userData != null) {
      return UserModel.fromJson(json.decode(userData));
    }
    
    return null;
  }
}