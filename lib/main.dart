import 'package:flutter/material.dart';

import 'core/tema.dart';

void main() => runApp(const PusulaUygulamasi());

class PusulaUygulamasi extends StatelessWidget {
  const PusulaUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kamu Pusulası',
      debugShowCheckedModeBanner: false,
      theme: pusulaTema(),
      home: const Scaffold(body: Center(child: Text('Kamu Pusulası'))),
    );
  }
}
