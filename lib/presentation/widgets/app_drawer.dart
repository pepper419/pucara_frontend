import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AppDrawer extends StatelessWidget {
  final String nombreUsuario;

  AppDrawer({required this.nombreUsuario});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.blanco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.azulIntermedio,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.celesteClaro,
                  child: Icon(Icons.person, size: 36, color: AppColors.azulOscuro),
                ),
                SizedBox(height: 10),
                Text(
                  nombreUsuario,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  "Cuenta bancaria segura",
                  style: TextStyle(color: Colors.white70),
                )
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: AppColors.azulIntermedio),
            title: Text('Inicio'),
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          ListTile(
            leading: Icon(Icons.history, color: AppColors.azulIntermedio),
            title: Text('Historial'),
            onTap: () => Navigator.pushNamed(context, '/historial'),
          ),
          ListTile(
            leading: Icon(Icons.school, color: AppColors.azulIntermedio),
            title: Text('Educación'),
            onTap: () => Navigator.pushNamed(context, '/educacion'),
          ),
          ListTile(
            leading: Icon(Icons.quiz, color: AppColors.azulIntermedio),
            title: Text('Cuestionarios'),
            onTap: () => Navigator.pushNamed(context, '/cuestionario'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}