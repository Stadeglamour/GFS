import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ajout.dart';
import 'search.dart';
import 'favoris.dart';
import 'profil.dart';
import 'detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SupabaseClient supabase;
  late Future<List<Map<String, dynamic>>> filmsFuture;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    filmsFuture = fetchFilms();
  }

  // Fonction qui récupère les films depuis la table 'film' de Supabase
  Future<List<Map<String, dynamic>>> fetchFilms() async {
    final response = await supabase.from('film').select().execute();

    final List films = response.data ?? [];
    return films.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    //****************************************************************
    // Définition du contrôleur de Tab avec 3 onglets : FILMS, SÉRIES, ACTEURS
    //****************************************************************
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        //****************************************************************
        // AppBar avec TabBar pour la navigation entre FILMS, SÉRIES et ACTEURS
        //****************************************************************
        appBar: AppBar(
          automaticallyImplyLeading: false, // Pas de flèche retour dans l'AppBar
          backgroundColor: Colors.white,
          elevation: 1,
          title: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'FILMS'),
              Tab(text: 'SÉRIES'),
              Tab(text: 'ACTEURS'),
            ],
          ),
        ),

        //****************************************************************
        // Contenu de chaque onglet : FILMS, SÉRIES, ACTEURS
        //****************************************************************
        body: TabBarView(
          children: [
            // 🟢 FILMS - récupère les données dynamiques depuis Supabase
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Films populaires",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // FutureBuilder pour afficher la liste des films
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: filmsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text('Erreur : ${snapshot.error}');
                      }
                      final films = snapshot.data ?? [];
                      if (films.isEmpty) {
                        return const Text('Aucun film trouvé');
                      }

                      // Liste horizontale des films
                      return SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: films.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final film = films[index];
                            return mediaCard(
                              title: film['nom'] ?? 'Titre inconnu',
                              imageUrl: film['img'] ?? '',
                              // Ajout du comportement au clic sur la carte
                              onTap: () {
                                // Navigation vers la page détail en passant les données du film
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailPage(film: film),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 🔵 SÉRIES - données statiques pour l'instant
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Séries à ne pas manquer",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      mediaCard(title: "Breaking Bad"),
                      const SizedBox(width: 12),
                      mediaCard(title: "Stranger Things"),
                      const SizedBox(width: 12),
                      mediaCard(title: "Dark"),
                      const SizedBox(width: 12),
                      mediaCard(title: "The Witcher"),
                    ],
                  ),
                ),
              ],
            ),

            // 🟣 ACTEURS - données statiques pour l'instant
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Acteurs en vedette",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    mediaCard(title: "Leonardo DiCaprio"),
                    mediaCard(title: "Zendaya"),
                    mediaCard(title: "Robert Downey Jr."),
                    mediaCard(title: "Florence Pugh"),
                  ],
                ),
              ],
            ),
          ],
        ),

        //****************************************************************
        // Barre de navigation en bas (BottomNavigationBar)
        //****************************************************************
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Affiche tous les labels même si > 3
          currentIndex: 0, // Index sélectionné par défaut (modifiable dynamiquement)
          selectedItemColor: Colors.green, // Couleur élément actif
          unselectedItemColor: Colors.black54, // Couleur éléments inactifs
          showUnselectedLabels: true, // Affiche les labels non sélectionnés
          onTap: (index) {
            // Navigation vers les différentes pages selon l'item tapé
            switch (index) {
              case 1: // 🔍 Recherche
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
                break;
              case 2: // ➕ Ajout
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AjoutPage()),
                );
                break;
              case 3: // 📌 Favoris
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavorisPage()),
                );
                break;
              case 4: // 👤 Profil
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilPage()),
                );
                break;
              default:
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Rechercher',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  //****************************************************************
  // Widget pour créer une carte média (image + titre) avec possibilité de clic
  //****************************************************************
  Widget mediaCard({required String title, String? imageUrl, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap, // Déclenche la navigation si onTap est défini
      child: SizedBox(
        width: 120,
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // CENTRER horizontalement
          children: [
            Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                image: (imageUrl != null && imageUrl.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.white,
                child: Text(
                  title,
                  textAlign: TextAlign.center, // CENTRER le texte à l’intérieur du container
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
