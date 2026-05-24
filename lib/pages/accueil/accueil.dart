import 'package:flutter/material.dart';
import 'package:untitled11/pages/finance/finance.dart';
import 'package:untitled11/pages/evens/even.dart';
import 'package:untitled11/pages/membre/membres.dart';
import 'package:untitled11/pages/materielles/materielles.dart';

class Accueil extends StatefulWidget {
  const Accueil({super.key});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Palette Chromatique Haute Qualité (Style Vercel / Linear)
    const bgObsidian = Color(0xFF08090C);
    const surfaceInk = Color(0xFF111217);
    const borderSubtle = Color(0xFF20222B);
    const textMuted = Color(0xFF7E8494);

    return Scaffold(
      backgroundColor: bgObsidian,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================================================
                // EN-TÊTE CHIRURGICAL
                // =========================================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "CONSOLE DE GESTION",
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Amour Parfait",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderNotificationButton(onTap: () {}),
                  ],
                ),

                const SizedBox(height: 32),

                // =========================================================================
                // STATUS DE L'INFRASTRUCTURE
                // =========================================================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceInk,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Système opérationnel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text("v1.0.4", style: TextStyle(color: textMuted, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // =========================================================================
                // BENTO LAYOUT (ASYMÉTRIE PREMIUM)
                // =========================================================================
                const Text(
                  "Services principaux",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),

                // MODULE 1 : Large Horizontal (Focus UX sur les membres)
                _BentoCardHorizontal(
                  title: "Membres & Fidèles",
                  subtitle:
                      "Registre centralisé, fiches individuelles et statistiques d'engagement.",
                  icon: Icons.face_retouching_natural_rounded,
                  onTap: () => _navigateTo(const MembresPage()),
                ),
                const SizedBox(height: 12),

                // MODULE 2 & 3 : Grille Double Asymétrique (Finances & Événements)
                Row(
                  children: [
                    Expanded(
                      flex: 11, // Légèrement plus grand pour la data financière
                      child: _BentoCardVertical(
                        title: "Finances",
                        subtitle: "Flux de trésorerie",
                        icon: Icons.wallet_rounded,
                        extraWidget: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: const [
                              Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 4),
                              Text(
                                "Rapports à jour",
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => _navigateTo(const Finances()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 9,
                      child: _BentoCardVertical(
                        title: "Événements",
                        subtitle: "Planning & cultes",
                        icon: Icons.calendar_today_rounded,
                        onTap: () => _navigateTo(const NovaPayFinancePage()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // MODULE 4 : Large Horizontal Bas (Logistique et Matériels)
                _BentoCardHorizontal(
                  title: "Gestion des Matériels",
                  subtitle: "Inventaire complet des équipements, états et suivis des stocks.",
                  icon: Icons.backpack_outlined,
                  onTap: () => _navigateTo(const ChurchAssetPage()),
                ),

                const SizedBox(height: 48),

                // =========================================================================
                // FOOTER COMPACT
                // =========================================================================
                const Center(
                  child: Text(
                    "Respect • Sainteté • Adoration",
                    style: TextStyle(color: textMuted, fontSize: 11, letterSpacing: 1.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET : BOUTON NOTIFICATION STYLE LOGICIEL
// =========================================================================
class _HeaderNotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HeaderNotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111217),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF20222B)),
        ),
        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// =========================================================================
// WIDGET : CARTE BENTO HORIZONTALE (PREMIUM)
// =========================================================================
class _BentoCardHorizontal extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _BentoCardHorizontal({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_BentoCardHorizontal> createState() => _BentoCardHorizontalState();
}

class _BentoCardHorizontalState extends State<_BentoCardHorizontal> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111217),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? const Color(0xFF434756) : const Color(0xFF20222B),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardIconBox(icon: widget.icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(color: Color(0xFF7E8494), fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF373A46), size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET : CARTE BENTO VERTICALE (PREMIUM)
// =========================================================================
class _BentoCardVertical extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? extraWidget;
  final VoidCallback onTap;

  const _BentoCardVertical({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.extraWidget,
    required this.onTap,
  });

  @override
  State<_BentoCardVertical> createState() => _BentoCardVerticalState();
}

class _BentoCardVerticalState extends State<_BentoCardVertical> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF111217),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? const Color(0xFF434756) : const Color(0xFF20222B),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardIconBox(icon: widget.icon),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(color: Color(0xFF7E8494), fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.extraWidget != null) widget.extraWidget!,
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET SUBAQUATIQUE : CONTENEUR D'ICÔNE INTERNE
// =========================================================================
class _CardIconBox extends StatelessWidget {
  final IconData icon;
  const _CardIconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D303E), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
