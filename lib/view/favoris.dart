import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ajout.dart';
import 'home.dart';
import 'search.dart';
import 'profil.dart';
import 'detail.dart'; // pour la navigation vers la page de détail

class FavorisPage extends StatefulWidget {
  const FavorisPage({super.key});

  @override
  State<FavorisPage> createState() => _FavorisPageState(); // ✅ Correction : ajout de la parenthèse
}

class _FavorisPageState extends State<FavorisPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  late final String? _userId;
  late final Stream<List<Map<String, dynamic>>> _favorisStream;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    _userId = user?.id;

    if (_userId != null) {
      // Création d'un stream qui écoute les changements sur la table 'favoris' pour cet user
      _favorisStream = supabase
          .from('favoris')
          .stream(primaryKey: ['user_id', 'film_id', 'serie_id'])
          .eq('user_id', _userId!)
          .map((maps) => List<Map<String, dynamic>>.from(maps));
    } else {
      // Pas d'utilisateur connecté -> stream vide
      _favorisStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoris"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _favorisStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }

          final favoris = snapshot.data ?? [];

          if (favoris.isEmpty) {
            return const Center(child: Text("Aucun favori pour le moment."));
          }

          // Séparer les IDs de films et de séries
          final filmIds = favoris
              .where((fav) => fav['film_id'] != null)
              .map((fav) => fav['film_id'] as int)
              .toList();

          final serieIds = favoris
              .where((fav) => fav['serie_id'] != null)
              .map((fav) => fav['serie_id'] as int)
              .toList();

          return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _fetchFavorisDetails(filmIds, serieIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Erreur: ${snapshot.error}"));
              }

              final films = snapshot.data!['films']!;
              final series = snapshot.data!['series']!;

              // Fusion des films et séries avec indication du type
              final allItems = [
                ...films.map((f) => {'type': 'film', 'data': f}),
                ...series.map((s) => {'type': 'serie', 'data': s}),
              ];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  final data = item['data'] as Map<String, dynamic>;
                  final isFilm = item['type'] == 'film';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: data['img'] != null
                          ? Image.network(
                              data['img'],
                              width: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.movie),
                      title: Text(data['nom'] ?? 'Titre inconnu'),
                      subtitle: Text(isFilm ? 'Film' : 'Série'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              film: isFilm ? data : null,
                              serie: !isFilm ? data : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      //****************************************************************
      // Barre de navigation en bas
      //****************************************************************
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // Favoris
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 3) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AjoutPage()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
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

  // Fonction pour récupérer les infos des films et séries favoris
  Future<Map<String, List<Map<String, dynamic>>>> _fetchFavorisDetails(
    List<int> filmIds,
    List<int> serieIds,
  ) async {
    final futures = <Future<List<Map<String, dynamic>>>>[];

    if (filmIds.isNotEmpty) {
      futures.add(
        supabase
            .from('film')
            .select()
            .in_('id', filmIds)
            .order('nom')
            .then((res) => List<Map<String, dynamic>>.from(res)),
      );
    } else {
      futures.add(Future.value([]));
    }

    if (serieIds.isNotEmpty) {
      futures.add(
        supabase
            .from('serie')
            .select()
            .in_('id', serieIds)
            .order('nom')
            .then((res) => List<Map<String, dynamic>>.from(res)),
      );
    } else {
      futures.add(Future.value([]));
    }

    final results = await Future.wait(futures);
    return {
      'films': results[0],
      'series': results[1],
    };
  }
}
