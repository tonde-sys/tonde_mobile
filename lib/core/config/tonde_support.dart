/// Coordonnées du support TONDE, publiées dans l'application.
///
/// Elles vivent ici et non dans `AppConfig` (qui lit des `--dart-define`) pour
/// une raison simple : ce sont des coordonnées **produit**, pas des secrets
/// d'environnement. Un numéro fourni à la compilation obligeait à reconstruire
/// l'APK pour changer un numéro de support — or c'est précisément la donnée
/// qu'on change le plus souvent.
///
/// Le numéro n'est jamais affiché en clair côté interface : seule l'icône
/// téléphone est proposée, et le composeur du téléphone montre le numéro. C'est
/// une demande explicite du produit, et c'est aussi plus lisible sur un écran
/// étroit.
abstract final class TondeSupport {
  /// Numéro international sans `+` ni espaces : format attendu par `tel:` et
  /// par `wa.me`. `+257 71 16 57 41`.
  static const String phone = '25771165741';

  /// Même numéro que le téléphone : TONDE répond sur WhatsApp au même endroit.
  static const String whatsapp = '25771165741';

  static const String email = 'vitalzagabe156@gmail.com';
}
