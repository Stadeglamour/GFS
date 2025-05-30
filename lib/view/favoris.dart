import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ajout.dart';
import 'home.dart';
import 'search.dart';
import 'profil.dart';

class FavorisPage extends StatefulWidget {
  const FavorisPage({super.key});

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _favoris = [];
  bool _isLoading = true;
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
          .stream(primaryKey: ['user_id', 'film_id'])
          .eq('user_id', _userId!)
          .map((maps) => List<Map<String, dynamic>>.from(maps));
    } else {
      // Pas d'utilisateur connecté -> stream vide
      _favorisStream = Stream.value([]);
    }
  }

  // Fonction pour récupérer la liste des favoris avec info film (jointure)
  Future<List<Map<String, dynamic>>> _fetchFavoris() async {
    if (_userId == null) return [];

    final data = await supabase
        .from('favoris')
        .select('film_id, films(nom, img)')
        .eq('user_id', _userId);

    return List<Map<String, dynamic>>.from(data);
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
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun favori pour le moment."));
          }

          // Récupérer l'id des films favoris dans la liste snapshot.data!
          final filmIds = snapshot.data!.map((fav) => fav['film_id']).toList();

          // On récupère les infos complètes des films en une requête (optimisé)
          return FutureBuilder<List<Map<String, dynamic>>>(
  future: supabase
      .from('film') // ou 'films' selon ta BDD
      .select()
      .in_('id', filmIds)
      .order('nom', ascending: true)
      .execute()
      .then((response) {
       
        return List<Map<String, dynamic>>.from(response.data as List);
      }),
  builder: (context, filmSnapshot) {
    if (filmSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (filmSnapshot.hasError) {
      return Center(child: Text("Erreur films: ${filmSnapshot.error}"));
    }
    if (!filmSnapshot.hasData || filmSnapshot.data!.isEmpty) {
      return const Center(child: Text("Aucun film trouvé."));
    }

    final films = filmSnapshot.data!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: film['img'] != null
                ? Image.network(
                    film['img'],
                    width: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.movie),
            title: Text(film['nom'] ?? 'Titre inconnu'),
            onTap: () {
              // Optionnel: navigation vers détail film
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
}
