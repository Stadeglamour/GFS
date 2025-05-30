import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ajout.dart';
import 'home.dart';
import 'favoris.dart';
import 'profil.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  String searchQuery = '';
  String selectedType = 'Tous';
  String selectedGenre = 'Tous';
  bool sortByNewest = true;

  List<Map<String, dynamic>> results = [];
  List<String> genres = [];

  final List<String> types = ['Tous', 'Film', 'Série', 'Acteur'];

  @override
  void initState() {
    super.initState();
    fetchGenres();
    fetchData();
  }

  // 🔄 Récupération des résultats selon le type sélectionné
  Future<void> fetchData() async {
    String table;
    switch (selectedType) {
      case 'Film':
        table = 'film';
        break;
      case 'Série':
        table = 'serie';
        break;
      case 'Acteur':
        table = 'acteur';
        break;
      default:
        table = 'film'; // Par défaut, on utilise 'film'
    }

    dynamic query = supabase.from(table).select();

    if (searchQuery.isNotEmpty) {
      query = query.ilike('nom', '%$searchQuery%');
    }

    if (selectedGenre != 'Tous' && selectedType != 'Acteur') {
      query = query.eq('cathegorie', selectedGenre);
    }

    // On tri uniquement si la table contient une colonne 'date'
    if (selectedType != 'Acteur') {
      query = query.order('date', ascending: !sortByNewest);
    }

    final response = await query;

    setState(() {
      results = List<Map<String, dynamic>>.from(response);
    });
  }

  // 🎭 Récupération des genres uniquement depuis la table `film`
  Future<void> fetchGenres() async {
    final response = await supabase.from('film').select('cathegorie');

    final uniqueGenres = response
        .map((item) => item['cathegorie'] as String?)
        .where((genre) => genre != null && genre.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      genres = ['Tous', ...uniqueGenres.cast<String>()];
    });
  }

  // 📦 Widget d'affichage des résultats
  Widget buildResultCard(Map<String, dynamic> item) {
    final imageUrl = item['img'] ?? '';
    final title = item['nom'] ?? 'Titre inconnu';
    final subtitle = selectedType == 'Acteur'
        ? item['nationalite'] ?? 'Nationalité inconnue'
        : '${item['cathegorie'] ?? 'Genre inconnu'} - ${item['date'] ?? ''}';

    return ListTile(
      leading: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            )
          : const Icon(Icons.broken_image),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recherche"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un titre',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
                fetchData();
              },
            ),
          ),

          // 🔘 Filtres (Type, Genre, Année)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // 📂 Type
                DropdownButton<String>(
                  value: selectedType,
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                    fetchData();
                  },
                  items: types
                      .map((type) => DropdownMenuItem(
                          value: type, child: Text(type)))
                      .toList(),
                ),
                const SizedBox(width: 10),

                // 🎬 Genre
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedGenre,
                    isExpanded: true,
                    hint: const Text("Genre"),
                    onChanged: (value) {
                      setState(() => selectedGenre = value!);
                      fetchData();
                    },
                    items: genres.map((genre) {
                      return DropdownMenuItem(
                          value: genre, child: Text(genre));
                    }).toList(),
                  ),
                ),

                // ⬆️⬇️ Tri année
                IconButton(
                  tooltip: sortByNewest
                      ? "Du plus récent au plus ancien"
                      : "Du plus ancien au plus récent",
                  icon: Icon(sortByNewest
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
                  onPressed: () {
                    setState(() => sortByNewest = !sortByNewest);
                    fetchData();
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // 📋 Liste des résultats
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('Aucun résultat trouvé'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return buildResultCard(results[index]);
                    },
                  ),
          ),
        ],
      ),

      // ⛵ Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 1) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AjoutPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FavorisPage()));
              break;
            case 4:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilPage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
