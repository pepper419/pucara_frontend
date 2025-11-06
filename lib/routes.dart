import 'package:flutter/material.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/historial_view.dart';
import 'views/educacion_view.dart';
import 'views/cuestionario_view.dart';
import 'views/register.dart';
import 'views/perfil_view.dart';
import 'views/home_admin_view.dart';
import 'views/recuperar_view.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => LoginView(),
  '/home': (context) => HomeView(),
  '/register': (context) => RegisterView(),
  '/historial': (context) => HistorialView(),
  '/educacion': (context) => EducacionView(),
  '/cuestionario': (context) => CuestionarioView(),
  '/perfil': (context) => PerfilView(),
  '/home-admin': (context) => HomeAdminView(),
  '/recuperar': (context) => RecuperarView(),
};