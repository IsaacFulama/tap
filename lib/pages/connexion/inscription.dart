import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔒 Firebase Auth Core
import 'package:untitled11/pages/accueil/accueil.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifierAuthentificationExistante();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _verifierAuthentificationExistante() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final utilisateurActuel = FirebaseAuth.instance.currentUser;
      if (utilisateurActuel != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Accueil()));
      }
    });
  }

  Future<void> _traiterInscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Accueil()));
      }
    } on FirebaseAuthException catch (e) {
      String messageErreur = "Une erreur est survenue lors de l'inscription.";

      if (e.code == 'weak-password') {
        messageErreur = "Le mot de passe fourni est trop faible.";
      } else if (e.code == 'email-already-in-use') {
        messageErreur = "Un compte existe déjà pour cette adresse e-mail.";
      } else if (e.code == 'invalid-email') {
        messageErreur = "L'adresse e-mail n'est pas valide.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF453A),
            content: Text(
              messageErreur,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur système : ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Amour Parfait Tab",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.church_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      "Créer un compte de gestion",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Accédez au panneau d'administration de votre ministère.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: "Adresse e-mail institutionnelle",
                        icon: Icons.mail_outline_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "L'e-mail est requis";
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) return "Format d'e-mail invalide";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _traiterInscription(),
                      decoration: _inputDecoration(
                        hint: "Mot de passe",
                        icon: Icons.lock_open_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: const Color(0xFF555555),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? "Le mot de passe doit contenir au moins 6 caractères"
                          : null,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _traiterInscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Text(
                              "Continuer",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const ConnexionPage()),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                          children: [
                            TextSpan(text: "Vous avez déjà un compte ? "),
                            TextSpan(
                              text: "Se connecter",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 🌐 VRAI ÉCRAN DE CONNEXION RELIÉ À FIREBASE AUTH
// =========================================================================
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🛰️ COUCHE MÉTIER : Authentification de l'utilisateur existant sur Firebase
  Future<void> _traiterConnexion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Connexion à Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Accueil()));
      }
    } on FirebaseAuthException catch (e) {
      String messageErreur = "Une erreur est survenue lors de la connexion.";

      // Gestion des codes d'erreurs d'authentification Firebase
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        messageErreur = "Identifiants incorrects. Veuillez réessayer.";
      } else if (e.code == 'invalid-email') {
        messageErreur = "L'adresse e-mail n'est pas valide.";
      } else if (e.code == 'user-disabled') {
        messageErreur = "Ce compte utilisateur a été désactivé.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF453A),
            content: Text(
              messageErreur,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur système : ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_person_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      "Se connecter à la console",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Entrez vos identifiants pour gérer le ministère.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    // Champ Email de connexion
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: "Votre adresse e-mail",
                        icon: Icons.mail_outline_rounded,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "L'e-mail est requis" : null,
                    ),
                    const SizedBox(height: 16),

                    // Champ Mot de passe de connexion
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _traiterConnexion(),
                      decoration: _inputDecoration(
                        hint: "Votre mot de passe",
                        icon: Icons.lock_open_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: const Color(0xFF555555),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Le mot de passe est requis" : null,
                    ),
                    const SizedBox(height: 32),

                    // Bouton Se connecter
                    ElevatedButton(
                      onPressed: _isLoading ? null : _traiterConnexion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Text(
                              "Se connecter",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton pour basculer vers l'inscription
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Inscription()),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                          children: [
                            TextSpan(text: "Nouveau ici ? "),
                            TextSpan(
                              text: "Créer un compte",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Décoration partagée des inputs
InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF555555)),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFF141414),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF222222)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFFF453A), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFFF453A), width: 1),
    ),
    errorStyle: const TextStyle(color: Color(0xFFFF453A), fontSize: 11),
  );
}
