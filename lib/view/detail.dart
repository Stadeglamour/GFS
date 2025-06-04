import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic>? film;
  final Map<String, dynamic>? serie;
  final Map<String, dynamic>? acteur;

  const DetailPage({super.key, this.film, this.serie, this.acteur});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _critiques = [];
  bool _isFavori = false;

  bool get isFilm => widget.film != null;
  bool get isSerie => widget.serie != null;
  bool get isActeur => widget.acteur != null;

  Map<String, dynamic> get item => widget.film ?? widget.serie ?? widget.acteur!;

  @override
  void initState() {
    super.initState();
    if (!isActeur) {
      _loadCritiques();
      _checkFavori();
    }
  }

  Future<void> _checkFavori() async {
    final user = supabase.auth.currentUser;
    if (user == null || isActeur) return;

    final query = supabase.from('favoris').select().eq('user_id', user.id);
    if (isFilm) {
      query.eq('film_id', item['id']);
    } else {
      query.eq('serie_id', item['id']);
    }

    final response = await query.maybeSingle();

    setState(() {
      _isFavori = response != null;
    });
  }

  Future<void> _toggleFavori() async {
    final user = supabase.auth.currentUser;
    if (user == null || isActeur) return;

    if (_isFavori) {
      final deleteQuery = supabase.from('favoris').delete().eq('user_id', user.id);
      if (isFilm) {
        deleteQuery.eq('film_id', item['id']);
      } else {
        deleteQuery.eq('serie_id', item['id']);
      }
      await deleteQuery;
    } else {
      await supabase.from('favoris').insert({
        'user_id': user.id,
        if (isFilm) 'film_id': item['id'] else 'serie_id': item['id'],
      });
    }

    setState(() {
      _isFavori = !_isFavori;
    });
  }

  Future<void> _loadCritiques() async {
    try {
      final query = supabase
          .from('avis')
          .select('note, commentaire, profils!fk_avis_profil(pseudo)');

      if (isFilm) {
        query.eq('film_id', item['id']);
      } else {
        query.eq('serie_id', item['id']);
      }

      final data = await query;

      setState(() {
        _critiques = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement des critiques : $e");
    }
  }

  Future<String?> _getProfilIdForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final profil = await supabase
        .from('profils')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    return profil?['id'] as String?;
  }

  Future<void> submitReview(int note, String commentaire) async {
    final profilId = await _getProfilIdForCurrentUser();
    if (profilId == null) {
      print('Erreur : profil non trouvé pour l\'utilisateur connecté.');
      return;
    }

    final avis = {
      'profil_id': profilId,
      'note': note,
      'commentaire': commentaire,
      if (isFilm) 'film_id': item['id'] else 'serie_id': item['id'],
    };

    try {
      await supabase.from('avis').insert(avis);
      print('Avis inséré avec succès');
    } catch (e) {
      print('Erreur insertion avis : $e');
    }
  }

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

  Future<void> _submitReview() async {
    if (_rating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez donner une note et écrire une critique.')),
      );
      return;
    }

    await submitReview(_rating, _reviewController.text.trim());
    await _loadCritiques();

    setState(() {
      _rating = 0;
      _reviewController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item['nom'] ?? 'Détail'),
        actions: [
          if (!isActeur)
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
            if (item['img'] != null && item['img'].toString().isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item['img'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              item['nom'] ?? 'Nom inconnu',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (isActeur) ...[
              const SizedBox(height: 8),
              Text("Prénom : ${item['prenom'] ?? 'Non spécifié'}"),
              Text("Âge : ${item['age'] ?? 'Non spécifié'}"),
            ] else ...[
              const SizedBox(height: 8),
              Text("Catégorie : ${item['cathegorie'] ?? 'Non spécifiée'}"),
              Text("Âge recommandé : ${item['age'] ?? 'Non spécifié'}"),
              Text("Année de sortie : ${item['date'] ?? 'Inconnue'}"),
              const SizedBox(height: 16),
              const Text("Description :", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(item['description'] ?? 'Aucune description'),
              const Divider(height: 40),

              // Bloc note + critique
              const Text('Donner une note :', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(5, (index) => _buildStar(index + 1)),
              ),
              const SizedBox(height: 16),
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
              if (_critiques.isEmpty)
                const Text('Aucun avis pour cet élément.')
              else
                ..._critiques.map((c) {
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
          ],
        ),
      ),
    );
  }
}
