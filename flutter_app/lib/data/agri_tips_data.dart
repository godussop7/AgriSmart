class AgriTip {
  final String icon;
  final String title;
  final String message;
  final String category;

  const AgriTip({
    required this.icon,
    required this.title,
    required this.message,
    required this.category,
  });
}

const List<AgriTip> agriTips = [
  AgriTip(
    icon: '🌱',
    title: 'Semis optimal',
    message:
        'Semez tôt le matin ou en fin de journée pour limiter le stress hydrique des jeunes plants.',
    category: 'Semence',
  ),
  AgriTip(
    icon: '🌾',
    title: 'Récolte au bon moment',
    message:
        'Récoltez lorsque les grains sont fermes et secs. Évitez les périodes de forte pluie.',
    category: 'Récolte',
  ),
  AgriTip(
    icon: '💧',
    title: 'Gestion de l\'eau',
    message:
        'Privilégiez l\'irrigation goutte-à-goutte pour économiser l\'eau et améliorer les rendements.',
    category: 'Bonnes pratiques',
  ),
  AgriTip(
    icon: '📦',
    title: 'Stockage intelligent',
    message:
        'Stockez vos récoltes dans un endroit sec et aéré. Surveillez l\'humidité pour éviter les moisissures.',
    category: 'Stock',
  ),
  AgriTip(
    icon: '☀️',
    title: 'Météo & planning',
    message:
        'Consultez la météo avant les traitements et les récoltes. Adaptez vos sorties aux pics de chaleur.',
    category: 'Météo',
  ),
  AgriTip(
    icon: '💰',
    title: 'Prix du marché',
    message:
        'Comparez les prix entre marchés avant de vendre. Les écarts peuvent atteindre 15 à 25 %.',
    category: 'Prix',
  ),
  AgriTip(
    icon: '🐛',
    title: 'Protection des cultures',
    message:
        'Inspectez vos parcelles chaque semaine. Une détection précoce réduit les pertes de 40 %.',
    category: 'Bonnes pratiques',
  ),
  AgriTip(
    icon: '🧪',
    title: 'Fertilisation',
    message:
        'Analysez votre sol avant d\'appliquer les engrais. Un apport ciblé augmente le rendement.',
    category: 'Semence',
  ),
];
