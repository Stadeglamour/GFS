import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> film;

  const DetailPage({super.key, required this.film});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _critiques = [];
  bool _isFavori = false;

  @override
  void initState() {
    super.initState();
    _loadCritiques();
    _checkFavori();
  }

  // Vérifie si le film est déjà en favori pour l'utilisateur connecté
  Future<void> _checkFavori() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('favoris')
        .select()
        .eq('user_id', user.id)
        .eq('film_id', widget.film['id'])
        .maybeSingle();

    setState(() {
      _isFavori = response != null;
    });
  }

  // Ajoute ou retire un favori
  Future<void> _toggleFavori() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (_isFavori) {
      await supabase
          .from('favoris')
          .delete()
          .eq('user_id', user.id)
          .eq('film_id', widget.film['id']);
    } else {
      await supabase.from('favoris').insert({
        'user_id': user.id,
        'film_id': widget.film['id'],
      });
    }

    setState(() {
      _isFavori = !_isFavori;
    });
  }

  // Charger les critiques avec pseudo depuis la table profils via la relation profil_id -> profils.id
  Future<void> _loadCritiques() async {
    try {
      // Attention à spécifier la relation précise pour éviter les conflits (cf erreur précédente)
      final data = await supabase
          .from('avis')
          .select('note, commentaire, profils!fk_avis_profil(pseudo)')
          .eq('film_id', widget.film['id']);

      setState(() {
        _critiques = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement des critiques : $e");
    }
  }

  // Récupère le profil_id lié à l'utilisateur courant
  Future<String?> _getProfilIdForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final profil = await supabase
        .from('profils')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (profil == null) return null;

    return profil['id'] as String;
  }

  // Envoyer un avis quand utilisateur valide note + commentaire
  Future<void> submitReview(int filmId, int note, String commentaire) async {
    final profilId = await _getProfilIdForCurrentUser();
    if (profilId == null) {
      print('Erreur : profil non trouvé pour l\'utilisateur connecté.');
      return;
    }

    try {
      final response = await supabase.from('avis').insert({
        'profil_id': profilId,  // Utiliser profil_id (clé étrangère correcte)
        'film_id': filmId,
        'note': note,
        'commentaire': commentaire,
      });

      print('Avis inséré avec succès');
    } catch (e) {
      print('Erreur insertion avis : $e');
    }
  }

  // Construction des étoiles pour la notation
  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 32,
      ),
      onPressed: () {
        setState(() {
          _rating = index;
        });
      },
      tooltip: '$index étoile(s)',
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // Méthode pour gérer l'envoi de l'avis depuis le bouton
  Future<void> _submitReview() async {
    if (_rating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez donner une note et écrire une critique.')),
      );
      return;
    }

    await submitReview(widget.film['id'], _rating, _reviewController.text.trim());
    await _loadCritiques();

    setState(() {
      _rating = 0;
      _reviewController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final film = widget.film;

    return Scaffold(
      appBar: AppBar(
        title: Text(film['nom'] ?? 'Détail'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavori ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
            ),
            onPressed: _toggleFavori,
            tooltip: _isFavori ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (film['img'] != null && film['img'].toString().isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    film['img'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              film['nom'] ?? 'Titre inconnu',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Catégorie : ${film['cathegorie'] ?? 'Non spécifiée'}"),
            Text("Âge recommandé : ${film['age'] ?? 'Non spécifié'}"),
            Text("Année de sortie : ${film['date'] ?? 'Inconnue'}"),
            const SizedBox(height: 16),
            const Text("Description :", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(film['description'] ?? 'Aucune description'),
            const Divider(height: 40),

            // Section notation
            const Text('Donner une note :', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 16),

            // Section commentaire
            const Text('Écrire une critique :', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Votre critique ici...',
              ),
            ),
            const SizedBox(height: 16),

            // Bouton envoyer
            Center(
              child: ElevatedButton(
                onPressed: _submitReview,
                child: const Text('Envoyer'),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const Text('Avis existants :', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Affichage des critiques
            if (_critiques.isEmpty)
              const Text('Aucun avis pour ce film.')
            else
              ..._critiques.map((c) {
                // On récupère le pseudo depuis la jointure profils
                final pseudo = c['profils']?['pseudo'] ?? 'Utilisateur';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pseudo, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(
                          c['note'],
                          (index) => const Icon(Icons.star, size: 16, color: Colors.amber),
                        ),
                      ),
                      if (c['commentaire'] != null && c['commentaire'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(c['commentaire']),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
