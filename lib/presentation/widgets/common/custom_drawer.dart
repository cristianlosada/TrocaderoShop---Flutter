import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  final String tipoUsuario; // Tipo de usuario ("persona" o "empresa")

  const CustomDrawer({super.key, required this.tipoUsuario});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF643CB9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.purple),
                ),
                const SizedBox(height: 10),
                Text(
                  tipoUsuario == 'persona' ? 'Perfil de Persona' : 'Perfil de Empresa',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'Correo no disponible',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Muestra este ListTile solo si el tipo de usuario es 'persona'
          // if (tipoUsuario == 'empresa')
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Ver otras empresas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/other_companies');
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_quilt),
            title: const Text('Productos de otras empresas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/other_company_products');
            },
          ),
          if (tipoUsuario == 'empresa')
            ListTile(
              leading: const Icon(Icons.real_estate_agent),
              title: const Text('Mis ventas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/company_sales');
              },
            ),
          // usuario persona  
          if (tipoUsuario == 'persona')
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Mis compras'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/person_purchases');
              },
            ),
          // Lista de opciones
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              // Agrega la lógica para abrir el perfil del usuario aquí
              Navigator.pushNamed(context, '/profile');
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.settings),
          //   title: const Text('Configuraciones'),
          //   onTap: () {
          //     // Acción para configuraciones
          //   },
          // ),
          const Divider(), // Línea divisoria entre las opciones y el cierre de sesión
          // Botón de cierre de sesión en la parte inferior
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context); // Cierra el Drawer
                Navigator.pushReplacementNamed(context, '/login'); // Navega a login
              }
            },
          ),
        ],
      ),
    );
  }
}
