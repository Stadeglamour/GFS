import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final supabase = Supabase.instance.client;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pseudoController = TextEditingController();

  bool _isLogin = true;
  String? _errorMessage;
  String? _userPseudo;

  @override
  void initState() {
    super.initState();
    _fetchUserPseudo();
  }

Future<void> _fetchUserPseudo() async {
  final user = supabase.auth.currentUser;
  if (user != null) {
    final insertResponse = await supabase.from('profils').insert({
      'user_id': user.id,
      'pseudo': 'pseudoParDefaut', // ou un pseudo choisi par l’utilisateur
    });
    if (insertResponse.error != null) {
      print('Erreur création profil : ${insertResponse.error!.message}');
    }
  }
}

  Future<void> _handleSubmit() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    setState(() {
      _errorMessage = 'Veuillez remplir tous les champs.';
    });
    return;
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  if (!isValidEmail(email)) {
    setState(() {
      _errorMessage = 'L\'email n\'est pas valide.';
    });
    return;
  }

  try {
    if (_isLogin) {
      // Connexion
      final response = await supabase.auth.signInWithPassword(email: email, password: password);
      if (response.session != null) {
        setState(() {
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion réussie !')),
        );
      } else {
        setState(() {
          _errorMessage = 'Erreur inconnue lors de la connexion.';
        });
      }
    } else {
      // Inscription simplifiée : juste email et mdp
      final response = await supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        setState(() {
          _errorMessage = null;
          _isLogin = true; // Retourne au mode login après inscription
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie, connectez-vous.')),
        );
      } else {
        setState(() {
          _errorMessage = 'Erreur inconnue lors de l\'inscription.';
        });
      }
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur: $e';
    });
  }
}


  Future<void> _logout() async {
    await supabase.auth.signOut();
    setState(() {
      _userPseudo = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Connexion' : 'Inscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? Column(
                children: [
                  if (!_isLogin)
                    TextField(
                      controller: _pseudoController,
                      decoration: const InputDecoration(labelText: 'Pseudo'),
                    ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text(_isLogin ? 'Se connecter' : 'Créer un compte'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(_isLogin ? 'Créer un compte' : 'Se connecter'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Connecté en tant que : ${_userPseudo ?? user.email}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Déconnexion'),
                  ),
                ],
              ),
      ),
    );
  }
}


// test@gmail.com // test123
// test1@gmail.com // test123
// user@gmail.com // user123