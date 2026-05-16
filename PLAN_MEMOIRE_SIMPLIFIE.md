# PLAN DE MÉMOIRE - Naatal Agro
## Application Mobile pour l'Optimisation des Prix Agricoles au Sénégal

---

## Titre Proposé
"Conception et Développement d'une Application Mobile Intelligente pour l'Optimisation des Prix Agricoles au Sénégal : Cas de Naatal Agro"

---

## STRUCTURE EN 8 CHAPITRES

### Chapitre 1 : Introduction Générale (10-15 pages)
**1.1 Contexte et Problématique**
- Agriculture au Sénégal : enjeux économiques
- Information asymétrique sur les prix
- Digitalisation comme solution

**1.2 Objectifs**
- **Objectif général** : Concevoir une app mobile pour optimiser les prix agricoles
- **Objectifs spécifiques** :
  - OS1 : Analyser les besoins des agriculteurs
  - OS2 : Développer un système de prédiction IA
  - OS3 : Créer un chatbot agricole intelligent
  - OS4 : Évaluer l'impact de l'application

**1.3 Méthodologie**
- Approche mixte (qualitative + quantitative)
- Enquêtes terrain + entretiens
- Développement Agile

---

### Chapitre 2 : Revue de Littérature (15-20 pages)
**2.1 Agriculture Digitale en Afrique**
- État des lieux des initiatives existantes
- Applications similaires (M-Farm, Esoko)
- Opportunités au Sénégal

**2.2 Intelligence Artificielle en Agriculture**
- Prédiction des prix avec ML
- Chatbots agricoles
- API Gemini et LLMs

**2.3 UX/UI pour Contexte Africain**
- Design mobile-first
- Support multilingue
- Contraintes technologiques

---

### Chapitre 3 : Analyse des Besoins (15-20 pages)
**3.1 Méthodologie d'Investigation**
- Échantillon : agriculteurs de différentes régions
- Outils : questionnaires + entretiens semi-directifs

**3.2 Résultats des Enquêtes**
- Profil des utilisateurs
- Sources d'information actuelles
- Besoins prioritaires identifiés

**3.3 Spécifications Fonctionnelles**
- Cas d'utilisation principaux
- User stories prioritaires

---

### Chapitre 4 : Conception du Système (20-25 pages)
**4.1 Architecture Technique**
- Architecture 3-tiers (Client/Serveur/Base)
- Stack technologique : Django REST + React
- Intégration IA (Google Gemini)

**4.2 Modélisation UML**
- Diagramme des cas d'utilisation
- Diagramme de classes
- Diagrammes de séquence (principaux)

**4.3 Conception de la Base de Données**
- Modèle conceptuel (MCD)
- Tables principales : Produit, Prix, Marché, Utilisateur
- Relations et cardinalités

**4.4 Design UX/UI**
- Wireframes principaux
- Maquettes haute fidélité
- Design System (couleurs, typographie, composants)

---

### Chapitre 5 : Implémentation (25-30 pages)
**5.1 Développement Backend**
- Django REST Framework : configuration et structure
- Modules développés :
  - Authentification JWT
  - Gestion des produits et prix
  - API prédiction IA
  - Chatbot intelligent
- Intégration API externes (Gemini, OpenWeather)

**5.2 Développement Frontend**
- React : architecture et composants
- Interface utilisateur :
  - Dashboard
  - Carte interactive des marchés
  - Chatbot
  - Gestion des stocks
- Intégration API backend

**5.3 Système de Prédiction IA**
- Pipeline de données
- Prompt engineering pour Gemini
- Validation des prédictions

**5.4 Déploiement et Sécurité**
- Hébergement (Render/Heroku)
- Authentification sécurisée
- Tests de performance

---

### Chapitre 6 : Tests et Évaluation (15-20 pages)
**6.1 Stratégie de Test**
- Tests unitaires (couverture 80%+)
- Tests d'intégration
- Tests end-to-end

**6.2 Tests Utilisateurs**
- Protocole de test (5-10 utilisateurs)
- Tâches à accomplir
- Collecte de feedback

**6.3 Évaluation des Résultats**
- Score SUS (System Usability Scale)
- Taux de réussite des tâches
- Feedback qualitatif

**6.4 Validation des Objectifs**
- OS1 à OS4 : atteints ou non
- Hypothèses validées

---

### Chapitre 7 : Discussion (10-15 pages)
**7.1 Interprétation des Résultats**
- Forces de l'application
- Défis rencontrés
- Comparaison avec solutions existantes

**7.2 Contributions**
- Apport scientifique : nouvelle approche IA pour agriculture sénégalaise
- Apport pratique : outil utilisable par les agriculteurs

**7.3 Limites de l'Étude**
- Échantillon limité (période/région)
- Dépendance aux APIs externes

---

### Chapitre 8 : Conclusion et Perspectives (5-10 pages)
**8.1 Synthèse**
- Réponses aux objectifs
- Bilan du projet

**8.2 Perspectives**
- Améliorations futures :
  - Extension régionale
  - Intégration paiement mobile
  - Mode offline avancé
- Recommandations pour les acteurs du secteur

---

## RÉPARTITION DES PAGES

| Chapitre | Pages | Pourcentage |
|----------|-------|-------------|
| 1. Introduction | 10-15 | 8% |
| 2. Revue de Littérature | 15-20 | 12% |
| 3. Analyse des Besoins | 15-20 | 12% |
| 4. Conception | 20-25 | 18% |
| 5. Implémentation | 25-30 | 23% |
| 6. Tests et Évaluation | 15-20 | 12% |
| 7. Discussion | 10-15 | 8% |
| 8. Conclusion | 5-10 | 5% |
| **TOTAL** | **115-155** | **100%** |

---

## ANNEXES (Optionnelles)
- A : Questionnaires d'enquête
- B : Diagrammes UML complets
- C : Captures d'écran de l'application
- D : Code source (extraits)
- E : Glossaire

---

**Ce plan couvre l'essentiel : analyse, conception, développement, tests et conclusion.**
