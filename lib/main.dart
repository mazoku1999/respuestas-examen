import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_udid/flutter_udid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preguntas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _loading = true;
  bool _registered = false;
  late String _deviceId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Firebase.initializeApp();
    final udid = await FlutterUdid.udid;
    final id = (udid.hashCode.abs() % 100000).toString().padLeft(5, '0');
    _deviceId = id;
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(id)
        .get();
    if (doc.exists) {
      setState(() {
        _registered = true;
        _loading = false;
      });
    } else {
      setState(() {
        _registered = false;
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(_deviceId)
        .set({'registered': true});
    setState(() {
      _registered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_registered) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ID: $_deviceId'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      );
    }
    return const HomePage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<List<dynamic>> _loadQuestions(BuildContext context, String asset) async {
    final data = await DefaultAssetBundle.of(context).loadString(asset);
    return json.decode(data) as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona Preguntas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _setButton(context, 'Parte 1', 'assets/preguntas_parte1.json'),
            const SizedBox(height: 16),
            _setButton(context, 'Parte 2', 'assets/preguntas_parte2.json'),
          ],
        ),
      ),
    );
  }

  Widget _setButton(BuildContext context, String title, String asset) {
    return InkWell(
      onTap: () async {
        final questions = await _loadQuestions(context, asset);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionPage(title: title, questions: questions),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class QuestionPage extends StatefulWidget {
  final String title;
  final List<dynamic> questions;

  const QuestionPage({super.key, required this.title, required this.questions});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int _index = 0;
  bool? _isCorrect;

  Map<String, dynamic> get _current =>
      widget.questions[_index] as Map<String, dynamic>;

  void _check(Map<String, dynamic> option) {
    setState(() {
      _isCorrect = option['correct'] as bool;
    });
  }

  void _next() {
    if (_index < widget.questions.length - 1) {
      setState(() {
        _index++;
        _isCorrect = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final opciones = (_current['opciones'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _current['pregunta'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...opciones.map((o) => _optionTile(o)),
            const Spacer(),
            if (_isCorrect != null)
              Text(
                _isCorrect! ? 'Correcto!' : 'Incorrecto',
                style: TextStyle(
                  color: _isCorrect! ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _next,
              child: Text(_index < widget.questions.length - 1
                  ? 'Siguiente'
                  : 'Finalizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(Map<String, dynamic> o) {
    return GestureDetector(
      onTap: () => _check(o),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _isCorrect != null && o['correct'] == _isCorrect,
              onChanged: (_) => _check(o),
            ),
            Expanded(child: Text(o['texto'] as String)),
          ],
        ),
      ),
    );
  }
}
