import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Image sélectionnée (locale)
  File? _selectedImageFile;

  // Méthode pour sélectionner une image depuis la galerie
 Future<void> _pickImageFromGallery() async {
  var permission = await Permission.photos.request();

  if (permission.isGranted) {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  } else {
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(content: Text("Permission refusée pour accéder à la galerie.")),
    );
  }
}

  // Contrôleurs pour formulaire Film
  final _filmNomController = TextEditingController();
  String? _filmCategorie;
  final _filmAgeController = TextEditingController();
  final _filmDescriptionController = TextEditingController();
  final _filmImgController = TextEditingController();
  final _filmDateController = TextEditingController();

  final _formKeyFilm = GlobalKey<FormState>();

  // Controllers pour Série
  final _serieNomController = TextEditingController();
  String? _serieCategorie;
  final _serieAgeController = TextEditingController();
  final _serieDescriptionController = TextEditingController();
  final _serieImgController = TextEditingController();
  final _serieNbSaisonController = TextEditingController();
  final _serieDateController = TextEditingController();

  final _formKeySerie = GlobalKey<FormState>();

  // Contrôleurs pour Acteur (placeholder)
  final _acteurNomController = TextEditingController();
  final _acteurPrenomController = TextEditingController();
  final _acteurAgeController = TextEditingController();
  final _acteurImgController = TextEditingController();

  final _formKeyActeur = GlobalKey<FormState>();

  // Initialisation du TabController
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Méthode pour uploader une image locale vers Supabase Storage
Future<String?> _uploadImageToSupabase(File file) async {
  final supabase = Supabase.instance.client;
  final bucket = 'img';
  final fileName = 'images/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

  try {
    final bytes = await file.readAsBytes(); // ✅ lecture en bytes
    await supabase.storage.from(bucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(upsert: true), // ✅ remplace si fichier du même nom
    );

    final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
    return publicUrl;
  } catch (e) {
    print('Erreur upload : $e'); // ✅ log utile
    return null;
  }
}

  // Méthode pour insérer un film dans Supabase
  Future<void> _insertFilm() async {
    if (_formKeyFilm.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;

        String? finalImageUrl;

        // Cas 1 : image locale → upload vers Supabase
        if (_selectedImageFile != null && !_filmImgController.text.startsWith('http')) {
          finalImageUrl = await _uploadImageToSupabase(_selectedImageFile!);
        }

        // Cas 2 : image via URL
        else if (_filmImgController.text.startsWith('http')) {
          finalImageUrl = _filmImgController.text;
          print('✅ Image uploadée URL : $finalImageUrl');
        }

        await supabase.from('film').insert({
          'nom': _filmNomController.text,
          'cathegorie': _filmCategorie ?? '',
          'age': _filmAgeController.text,
          'description': _filmDescriptionController.text,
          'img': finalImageUrl ?? '',
          'date': int.tryParse(_filmDateController.text) ?? 0,
        });

        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('✅ Film ajouté avec succès !')),
        );

        _formKeyFilm.currentState!.reset();
        setState(() {
          _filmCategorie = null;
          _selectedImageFile = null;
          _filmImgController.clear();
        });

        Navigator.pop(this.context, true);
      } catch (e) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e')),
        );
      }
    }
  }

  // Méthode pour insérer une série (placeholder)
  Future<void> _insertSerie() async {
  if (_formKeySerie.currentState!.validate()) {
    try {
      final supabase = Supabase.instance.client;

      String? imageUrl;

      // Si une image locale est sélectionnée, on upload et récupère l'URL
      if (_selectedImageFile != null) {
        imageUrl = await _uploadImageToSupabase(_selectedImageFile!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'upload de l\'image')),
          );
          return;
        }
      } else if (_serieImgController.text.isNotEmpty) {
        // Sinon on utilise le lien URL saisi
        imageUrl = _serieImgController.text;
      }

      await supabase.from('serie').insert({
        'nom': _serieNomController.text,
        'cathegorie': _serieCategorie ?? '',
        'age': int.tryParse(_serieAgeController.text) ?? 0,
        'description': _serieDescriptionController.text,
        'img': imageUrl ?? '',
        'nb_saison': _serieNbSaisonController.text,
        'date': int.tryParse(_serieDateController.text) ?? 0,
      });

      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('✅ Série ajoutée avec succès !')),
      );

      _formKeySerie.currentState!.reset();
      setState(() {
        _serieCategorie = null;
        _selectedImageFile = null;
        _serieImgController.clear();
      });

      Navigator.pop(this.context, true);
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('❌ Erreur : $e')),
      );
    }
  }
}
  // Méthode pour insérer un acteur (placeholder)
  Future<void> _insertActeur() async {
    if (_formKeyActeur.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;

        String? imageUrl;

        // Si une image locale est sélectionnée, on upload et récupère l'URL
        if (_selectedImageFile != null) {
          imageUrl = await _uploadImageToSupabase(_selectedImageFile!);
          if (imageUrl == null) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Erreur lors de l\'upload de l\'image')),
            );
            return;
          }
        } else if (_acteurImgController.text.isNotEmpty) {
          // Sinon on utilise le lien URL saisi
          imageUrl = _acteurImgController.text;
        }

        await supabase.from('acteur').insert({
          'nom': _acteurNomController.text,
          'prenom': _acteurPrenomController.text,
          'age': int.tryParse(_acteurAgeController.text) ?? 0,
          'img': imageUrl ?? '',
        });

        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('✅ Acteur ajouté avec succès !')),
        );

        _formKeySerie.currentState!.reset();
        setState(() {
          _selectedImageFile = null;
          _acteurImgController.clear();
        });

        Navigator.pop(this.context, true);
      } catch (e) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e')),
        );
      }
    }
  }

  // Méthode pour valider les champs du formulaire
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

  // Méthode pour construire l'interface
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
          // === FORMULAIRE POUR FILM ===
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
                    items: genres.map((genre) => DropdownMenuItem(value: genre, child: Text(genre))).toList(),
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
                  // Section pour ajouter une image (locale ou URL)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image du film'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _filmImgController,
                              decoration: const InputDecoration(
                                hintText: 'URL de l\'image ou vide si image locale',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo),
                            tooltip: 'Choisir depuis la galerie',
                            onPressed: _pickImageFromGallery,
                          ),
                        ],
                      ),
                      if (_filmImgController.text.isNotEmpty || _selectedImageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _filmImgController.text.startsWith('http')
                              ? Image.network(_filmImgController.text, height: 150)
                              : _selectedImageFile != null
                                  ? Image.file(_selectedImageFile!, height: 150)
                                  : Container(),
                        ),
                    ],
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

          // === FORMULAIRE POUR SERIE ===
          // (placeholder - logique à compléter)
         Padding(
  padding: const EdgeInsets.all(16.0),
  child: Form(
    key: _formKeySerie,
    child: ListView(
      children: [
        TextFormField(
          controller: _serieNomController,
          decoration: const InputDecoration(labelText: 'Nom de la série'),
          validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
        ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Catégorie'),
          value: _serieCategorie,
          items: genres.map((genre) => DropdownMenuItem(value: genre, child: Text(genre))).toList(),
          onChanged: (val) => setState(() => _serieCategorie = val),
          validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
        ),
        TextFormField(
          controller: _serieAgeController,
          decoration: const InputDecoration(labelText: 'Âge recommandé'),
          keyboardType: TextInputType.number,
        ),
        TextFormField(
          controller: _serieDescriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
        ),
        TextFormField(
          controller: _serieNbSaisonController,
          decoration: const InputDecoration(labelText: 'Nombre de saisons'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Image de la série'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serieImgController,
                    decoration: const InputDecoration(
                      hintText: 'URL de l\'image ou vide si image locale',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.photo),
                  tooltip: 'Choisir depuis la galerie',
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImageFile = File(pickedFile.path);
                        _serieImgController.text = pickedFile.path;
                      });
                    }
                  },
                ),
              ],
            ),
            if (_serieImgController.text.isNotEmpty || _selectedImageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _serieImgController.text.startsWith('http')
                    ? Image.network(_serieImgController.text, height: 150)
                    : _selectedImageFile != null
                        ? Image.file(_selectedImageFile!, height: 150)
                        : Container(),
              ),
          ],
        ),
        TextFormField(
          controller: _serieDateController,
          decoration: const InputDecoration(labelText: 'Date de sortie'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _insertSerie,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Ajouter la série'),
        ),
      ],
    ),
  ),
),

          // === PLACEHOLDER POUR ACTEURS ===
           // (placeholder - logique à compléter)
         Padding(
  padding: const EdgeInsets.all(16.0),
  child: Form(
    key: _formKeyActeur,
    child: ListView(
      children: [
        TextFormField(
          controller: _acteurNomController,
          decoration: const InputDecoration(labelText: 'Nom Acteur'),
          validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
        ),
        TextFormField(
          controller: _acteurPrenomController,
          decoration: const InputDecoration(labelText: 'Prénom Acteur'),
          validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
        ),
        TextFormField(
          controller: _acteurAgeController,
          decoration: const InputDecoration(labelText: 'Âge Acteur'),
          keyboardType: TextInputType.number,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Image de l\'Acteur'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _acteurImgController,
                    decoration: const InputDecoration(
                      hintText: 'URL de l\'image ou vide si image locale',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.photo),
                  tooltip: 'Choisir depuis la galerie',
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImageFile = File(pickedFile.path);
                        _acteurImgController.text = pickedFile.path;
                      });
                    }
                  },
                ),
              ],
            ),
            if (_acteurImgController.text.isNotEmpty || _selectedImageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _acteurImgController.text.startsWith('http')
                    ? Image.network(_acteurImgController.text, height: 150)
                    : _selectedImageFile != null
                        ? Image.file(_selectedImageFile!, height: 150)
                        : Container(),
              ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _insertActeur,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Ajouter l\'acteur'),
        ),
      ],
    ),
  ),
),
        ],
      ),
    );
  }
}
