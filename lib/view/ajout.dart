import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AjoutPage extends StatefulWidget {
  const AjoutPage({super.key});

  @override
  State<AjoutPage> createState() => _AjoutPageState();
}

class _AjoutPageState extends State<AjoutPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> genres = [
    'Comédie',
    'Drame',
    'Comédie dramatique',
    'Thriller',
    'Action / Aventure',
    'Fiction',
    'Comédie romantique',
    'Animé',
    'Dessin animé',
    'Horreur',
    'Science-fiction',
    'Fantastique',
  ];

  // Controllers pour Film
  final _filmNomController = TextEditingController();
  String? _filmCategorie;
  final _filmAgeController = TextEditingController();
  final _filmDescriptionController = TextEditingController();
  final _filmImgController = TextEditingController();
  final _filmDateController = TextEditingController();

  final _formKeyFilm = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _insertFilm() async {
    if (_formKeyFilm.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;

        await supabase.from('film').insert({
          'nom': _filmNomController.text,
          'cathegorie': _filmCategorie ?? '',
          'age': _filmAgeController.text,
          'description': _filmDescriptionController.text,
          'img': _filmImgController.text,
          'date': int.tryParse(_filmDateController.text) ?? 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Film ajouté avec succès !')),
        );

        _formKeyFilm.currentState!.reset();
        setState(() {
          _filmCategorie = null;
        });

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _filmNomController.dispose();
    _filmAgeController.dispose();
    _filmDescriptionController.dispose();
    _filmImgController.dispose();
    _filmDateController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un film, une série ou un acteur'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'FILMS'),
            Tab(text: 'SÉRIES'),
            Tab(text: 'ACTEURS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ========== FORMULAIRE FILMS ==========
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKeyFilm,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _filmNomController,
                    decoration: const InputDecoration(labelText: 'Nom du film'),
                    validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    value: _filmCategorie,
                    items: genres
                        .map((genre) => DropdownMenuItem(value: genre, child: Text(genre)))
                        .toList(),
                    onChanged: (val) => setState(() => _filmCategorie = val),
                    validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                  ),
                  TextFormField(
                    controller: _filmAgeController,
                    decoration: const InputDecoration(labelText: 'Âge recommandé'),
                  ),
                  TextFormField(
                    controller: _filmDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextFormField(
                    controller: _filmImgController,
                    decoration: const InputDecoration(labelText: 'URL de l\'image'),
                  ),
                  TextFormField(
                    controller: _filmDateController,
                    decoration: const InputDecoration(labelText: 'Année de sortie'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _insertFilm,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Ajouter le film'),
                  ),
                ],
              ),
            ),
          ),

          // ========== PLACEHOLDER SERIES ==========
          const Center(child: Text('Formulaire SÉRIES à venir')),

          // ========== PLACEHOLDER ACTEURS ==========
          const Center(child: Text('Formulaire ACTEURS à venir')),
        ],
      ),
    );
  }
}
