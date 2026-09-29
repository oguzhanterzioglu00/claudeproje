import 'package:flutter/material.dart';

import 'core/tema.dart';

void main() => runApp(const KadroUygulamasi());

class KadroUygulamasi extends StatelessWidget {
  const KadroUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kadro',
      debugShowCheckedModeBanner: false,
      theme: kadroTema(),
      home: const Scaffold(body: Center(child: Text('Kadro'))),
    );
  }
}
