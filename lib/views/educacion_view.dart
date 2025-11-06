import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EducacionView extends StatefulWidget {
  @override
  _EducacionViewState createState() => _EducacionViewState();
}

class _EducacionViewState extends State<EducacionView> {
  final List<Map<String, dynamic>> contenidoCarding = [
    {
      "titulo": "¿Qué es el carding?",
      "descripcion":
      "El carding es un tipo de fraude donde delincuentes roban tus datos de tarjeta y hacen compras sin autorización.",
      "link": "https://www.sbs.gob.pe/usuarios/contenido/cyberseguridad-y-prevencion-del-fraude",
      "categoria": "Básico",
    },
    {
      "titulo": "Cómo proteger tus datos de tarjeta",
      "descripcion":
      "Nunca compartas tu número de tarjeta, CVV ni códigos por teléfono o redes. Usa páginas web seguras (https).",
      "link": "https://www.interbank.pe/blog/seguridad/datos-de-tu-tarjeta",
      "categoria": "Necesitas saberlo",
    },
    {
      "titulo": "Reconoce fraudes comunes en línea",
      "descripcion":
      "Cuidado con páginas falsas, links sospechosos y correos que fingen ser de tu banco. No ingreses tus datos en sitios no verificados.",
      "link": "https://www.bbva.pe/finanzas-practicas/seguridad-online.html",
      "categoria": "Necesitas saberlo",
    },
    {
      "titulo": "Consejos de la Asociación de Bancos del Perú (ASBANC)",
      "descripcion":
      "Sigue las recomendaciones de ASBANC para proteger tus medios de pago y evitar el fraude digital.",
      "link": "https://www.asbanc.com.pe/educacion-financiera/seguridad-digital/",
      "categoria": "Experto en ciberseguridad",
    },
    {
      "titulo": "¿Sufriste un posible fraude?",
      "descripcion":
      "Contacta inmediatamente a tu banco para bloquear tu tarjeta y reportar la operación sospechosa.",
      "link": "https://www.sbs.gob.pe/usuarios/reclamos-y-denuncias",
      "categoria": "Básico",
    },
    // Más contenido de ejemplo
    {
      "titulo": "Seguridad en redes Wi-Fi públicas",
      "descripcion":
      "Evita hacer operaciones bancarias en redes públicas para reducir riesgos de robo de datos.",
      "link": "https://www.certsi.gob.pe/noticias/seguridad-en-wi-fi-publico",
      "categoria": "Necesitas saberlo",
    },
    {
      "titulo": "Autenticación multifactor",
      "descripcion":
      "Activa la autenticación multifactor para mayor seguridad en tus cuentas bancarias y correos.",
      "link": "https://www.cisa.gov/uscert/ncas/tips/ST05-012",
      "categoria": "Experto en ciberseguridad",
    },
  ];

  // Estado para almacenar qué items se han leído (visitado)
  // Usaremos un Set con índices
  Set<int> itemsLeidos = {};

  // Colores por categoría
  final Map<String, Color> colorCategorias = {
    "Básico": Colors.green,
    "Necesitas saberlo": Colors.orange,
    "Experto en ciberseguridad": Colors.red,
  };

  void abrirLink(int index) async {
    final url = contenidoCarding[index]["link"] as String;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Marcar como leído cuando se abre el link
      setState(() {
        itemsLeidos.add(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prevención de Carding"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contenidoCarding.length,
        itemBuilder: (context, index) {
          final item = contenidoCarding[index];
          final categoria = item["categoria"] ?? "Básico";
          final colorCat = colorCategorias[categoria] ?? Colors.grey;
          final estaLeido = itemsLeidos.contains(index);

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item["titulo"],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorCat.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      categoria,
                      style: TextStyle(color: colorCat, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (estaLeido) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.green),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(item["descripcion"]),
              ),
              trailing: IconButton(
                icon: Icon(Icons.open_in_new, color: Colors.deepPurple),
                onPressed: () => abrirLink(index),
                tooltip: "Abrir recurso",
              ),
            ),
          );
        },
      ),
    );
  }
}
