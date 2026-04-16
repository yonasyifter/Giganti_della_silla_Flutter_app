import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../preferences/providers/user_preferences_provider.dart';

// ── Guide content model ───────────────────────────────────────────────────────
class _Section {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

// ── Multilingual content ──────────────────────────────────────────────────────
Map<String, List<_Section>> _guideContent = {
  'en': [
    _Section(
      icon: Icons.home_rounded,
      color: Color(0xFF4CAF50),
      title: 'Home Screen',
      body:
          'The Home screen is your starting point. It shows live park conditions '
          '(temperature, humidity, noise), your GPS status (inside/outside park), '
          'and the trail recommended for your preferences. Use the Quick Actions '
          'to jump to any feature instantly.',
    ),
    _Section(
      icon: Icons.map_rounded,
      color: Color(0xFF2196F3),
      title: 'Map & Trails',
      body:
          'The Map screen shows all available hiking trails as coloured polylines '
          'on an OpenStreetMap layer. Tap a trail marker to preview it, then tap '
          '"Start Trail" to begin your hike. Your GPS position is shown as a blue '
          'dot. The progress bar at the top updates as you walk the trail.',
    ),
    _Section(
      icon: Icons.tune_rounded,
      color: Color(0xFF9C27B0),
      title: 'Preferences',
      body:
          'Set your hiking preferences using the dropdown menus: difficulty, noise '
          'tolerance, primary interest (history or botany), slope preference, trail '
          'width, preferred vibe, and app language. Tap "Save Preferences" to '
          'instantly see trails matched to your profile.',
    ),
    _Section(
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFFF9800),
      title: 'AI Guide',
      body:
          'The AI Guide is your personal park assistant. Type or speak your '
          'question — it understands all five supported languages. Tap the '
          'microphone button to speak. The AI knows your location, the park '
          'conditions, and the trails. Ask about flora, fauna, history, safety, '
          'or directions.',
    ),
    _Section(
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF00BCD4),
      title: 'Tracking',
      body:
          'The Tracking screen shows your real-time hiker data: GPS coordinates, '
          'altitude, speed, heading, and phone sensors (battery, steps if '
          'available). It also shows your trail progress and total distance '
          'covered. Your location is shared with park rangers when you are inside '
          'the park for safety.',
    ),
    _Section(
      icon: Icons.local_parking_rounded,
      color: Color(0xFFFF5722),
      title: 'Parking Monitor',
      body:
          'The Parking screen lets you mark your car\'s parking spot with one tap. '
          'It saves the GPS coordinates and shows the distance from your current '
          'position. Use "Navigate to Car" to open directions in your maps app. '
          'The parking spot is saved locally and persists between sessions.',
    ),
    _Section(
      icon: Icons.cloud_rounded,
      color: Color(0xFF607D8B),
      title: 'Weather',
      body:
          'The Weather screen shows live sensor data from park IoT stations: '
          'temperature, humidity, air pressure, noise level, and light intensity. '
          'A forecast chart shows predicted conditions for the next hour. Data '
          'updates every 30 seconds from the park\'s sensor network.',
    ),
    _Section(
      icon: Icons.sos_rounded,
      color: Color(0xFFF44336),
      title: 'Emergency SOS',
      body:
          'In an emergency, tap the red SOS button (bottom-right of every screen). '
          'Hold the SOS button on the emergency screen to send an alert with your '
          'GPS coordinates to park rangers. Always ensure location permissions are '
          'granted. The SOS works even when offline by caching the alert.',
    ),
    _Section(
      icon: Icons.settings_rounded,
      color: Color(0xFF795548),
      title: 'Settings',
      body:
          'Access Settings from the profile avatar (top-right of Home). Here you '
          'can update your display name, change notification preferences, clear '
          'cached data, and view app version information.',
    ),
  ],
  'it': [
    _Section(
      icon: Icons.home_rounded,
      color: Color(0xFF4CAF50),
      title: 'Schermata Home',
      body:
          'La schermata Home è il tuo punto di partenza. Mostra le condizioni '
          'live del parco (temperatura, umidità, rumore), il tuo stato GPS '
          '(dentro/fuori dal parco) e il sentiero consigliato per le tue '
          'preferenze. Usa le Azioni Rapide per accedere a qualsiasi funzione.',
    ),
    _Section(
      icon: Icons.map_rounded,
      color: Color(0xFF2196F3),
      title: 'Mappa e Sentieri',
      body:
          'La schermata Mappa mostra tutti i sentieri disponibili come polilinee '
          'colorate su OpenStreetMap. Tocca un marcatore per l\'anteprima, poi '
          '"Inizia Sentiero" per iniziare l\'escursione. La tua posizione GPS è '
          'mostrata come un punto blu. La barra di avanzamento si aggiorna '
          'mentre cammini.',
    ),
    _Section(
      icon: Icons.tune_rounded,
      color: Color(0xFF9C27B0),
      title: 'Preferenze',
      body:
          'Imposta le tue preferenze di escursionismo tramite i menu a tendina: '
          'difficoltà, tolleranza al rumore, interesse principale (storia o '
          'botanica), preferenza di pendenza, larghezza del sentiero, atmosfera '
          'preferita e lingua dell\'app. Tocca "Salva Preferenze" per vedere '
          'subito i sentieri abbinati al tuo profilo.',
    ),
    _Section(
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFFF9800),
      title: 'Guida IA',
      body:
          'La Guida IA è il tuo assistente personale del parco. Digita o parla '
          'la tua domanda — capisce tutte e cinque le lingue supportate. Tocca '
          'il pulsante microfono per parlare. La IA conosce la tua posizione, '
          'le condizioni del parco e i sentieri. Chiedi di flora, fauna, '
          'storia, sicurezza o indicazioni.',
    ),
    _Section(
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF00BCD4),
      title: 'Tracciamento',
      body:
          'La schermata Tracciamento mostra i tuoi dati in tempo reale: '
          'coordinate GPS, altitudine, velocità, direzione e sensori del '
          'telefono (batteria, passi se disponibili). Mostra anche il '
          'progresso sul sentiero e la distanza totale percorsa. La tua '
          'posizione è condivisa con i ranger quando sei nel parco.',
    ),
    _Section(
      icon: Icons.local_parking_rounded,
      color: Color(0xFFFF5722),
      title: 'Monitor Parcheggio',
      body:
          'La schermata Parcheggio ti permette di segnare il posto dell\'auto '
          'con un tocco. Salva le coordinate GPS e mostra la distanza dalla '
          'tua posizione attuale. Usa "Naviga all\'Auto" per aprire le '
          'indicazioni. Il posto è salvato localmente e persiste tra le sessioni.',
    ),
    _Section(
      icon: Icons.cloud_rounded,
      color: Color(0xFF607D8B),
      title: 'Meteo',
      body:
          'La schermata Meteo mostra dati live dalle stazioni IoT del parco: '
          'temperatura, umidità, pressione, rumore e intensità luminosa. '
          'Un grafico previsionale mostra le condizioni attese per la '
          'prossima ora. I dati si aggiornano ogni 30 secondi.',
    ),
    _Section(
      icon: Icons.sos_rounded,
      color: Color(0xFFF44336),
      title: 'SOS Emergenza',
      body:
          'In caso di emergenza, tocca il pulsante rosso SOS (in basso a '
          'destra di ogni schermata). Tieni premuto il pulsante SOS per '
          'inviare un allarme con le tue coordinate GPS ai ranger. Assicurati '
          'che i permessi di posizione siano concessi.',
    ),
    _Section(
      icon: Icons.settings_rounded,
      color: Color(0xFF795548),
      title: 'Impostazioni',
      body:
          'Accedi alle Impostazioni dall\'avatar del profilo (in alto a destra '
          'nella Home). Qui puoi aggiornare il nome visualizzato, cambiare le '
          'preferenze di notifica, cancellare i dati in cache e vedere le '
          'informazioni sulla versione dell\'app.',
    ),
  ],
  'fr': [
    _Section(
      icon: Icons.home_rounded,
      color: Color(0xFF4CAF50),
      title: 'Écran d\'accueil',
      body:
          'L\'écran d\'accueil est votre point de départ. Il affiche les '
          'conditions en direct du parc (température, humidité, bruit), votre '
          'statut GPS (dans/hors du parc) et le sentier recommandé selon vos '
          'préférences. Utilisez les Actions Rapides pour accéder à n\'importe '
          'quelle fonctionnalité.',
    ),
    _Section(
      icon: Icons.map_rounded,
      color: Color(0xFF2196F3),
      title: 'Carte et Sentiers',
      body:
          'L\'écran Carte affiche tous les sentiers disponibles sous forme de '
          'polylignes colorées sur OpenStreetMap. Appuyez sur un marqueur pour '
          'l\'aperçu, puis "Démarrer le sentier" pour commencer la randonnée. '
          'Votre position GPS est affichée sous forme de point bleu.',
    ),
    _Section(
      icon: Icons.tune_rounded,
      color: Color(0xFF9C27B0),
      title: 'Préférences',
      body:
          'Définissez vos préférences de randonnée via les menus déroulants : '
          'difficulté, tolérance au bruit, intérêt principal (histoire ou '
          'botanique), préférence de pente, largeur du sentier, ambiance '
          'préférée et langue de l\'application.',
    ),
    _Section(
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFFF9800),
      title: 'Guide IA',
      body:
          'Le Guide IA est votre assistant personnel du parc. Tapez ou parlez '
          'votre question — il comprend les cinq langues supportées. Appuyez '
          'sur le bouton microphone pour parler. L\'IA connaît votre position, '
          'les conditions du parc et les sentiers.',
    ),
    _Section(
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF00BCD4),
      title: 'Suivi',
      body:
          'L\'écran Suivi affiche vos données en temps réel : coordonnées GPS, '
          'altitude, vitesse, cap et capteurs du téléphone (batterie, pas si '
          'disponibles). Il montre aussi votre progression sur le sentier et '
          'la distance totale parcourue.',
    ),
    _Section(
      icon: Icons.local_parking_rounded,
      color: Color(0xFFFF5722),
      title: 'Moniteur de Parking',
      body:
          'L\'écran Parking vous permet de marquer la place de votre voiture '
          'd\'un seul appui. Il enregistre les coordonnées GPS et affiche la '
          'distance depuis votre position actuelle. Utilisez "Naviguer vers '
          'la voiture" pour ouvrir les directions.',
    ),
    _Section(
      icon: Icons.cloud_rounded,
      color: Color(0xFF607D8B),
      title: 'Météo',
      body:
          'L\'écran Météo affiche les données en direct des stations IoT du '
          'parc : température, humidité, pression, bruit et intensité '
          'lumineuse. Un graphique de prévision montre les conditions '
          'attendues pour la prochaine heure.',
    ),
    _Section(
      icon: Icons.sos_rounded,
      color: Color(0xFFF44336),
      title: 'SOS Urgence',
      body:
          'En cas d\'urgence, appuyez sur le bouton SOS rouge (en bas à droite '
          'de chaque écran). Maintenez le bouton SOS pour envoyer une alerte '
          'avec vos coordonnées GPS aux rangers du parc.',
    ),
    _Section(
      icon: Icons.settings_rounded,
      color: Color(0xFF795548),
      title: 'Paramètres',
      body:
          'Accédez aux Paramètres depuis l\'avatar de profil (en haut à droite '
          'de l\'accueil). Vous pouvez mettre à jour votre nom, modifier les '
          'préférences de notification et effacer les données en cache.',
    ),
  ],
  'de': [
    _Section(
      icon: Icons.home_rounded,
      color: Color(0xFF4CAF50),
      title: 'Startbildschirm',
      body:
          'Der Startbildschirm ist Ihr Ausgangspunkt. Er zeigt Live-Parkbedingungen '
          '(Temperatur, Luftfeuchtigkeit, Lärm), Ihren GPS-Status (innerhalb/'
          'außerhalb des Parks) und den für Ihre Präferenzen empfohlenen Pfad. '
          'Nutzen Sie die Schnellaktionen für sofortigen Zugriff.',
    ),
    _Section(
      icon: Icons.map_rounded,
      color: Color(0xFF2196F3),
      title: 'Karte & Wanderwege',
      body:
          'Die Kartenansicht zeigt alle verfügbaren Wanderwege als farbige '
          'Polylinien auf OpenStreetMap. Tippen Sie auf eine Markierung für '
          'die Vorschau, dann "Weg starten" für die Wanderung. Ihre GPS-'
          'Position wird als blauer Punkt angezeigt.',
    ),
    _Section(
      icon: Icons.tune_rounded,
      color: Color(0xFF9C27B0),
      title: 'Einstellungen',
      body:
          'Legen Sie Ihre Wanderpräferenzen über Dropdown-Menüs fest: '
          'Schwierigkeit, Lärmtoleranz, Hauptinteresse (Geschichte oder '
          'Botanik), Hangneigung, Wegbreite, bevorzugte Atmosphäre und '
          'App-Sprache.',
    ),
    _Section(
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFFF9800),
      title: 'KI-Guide',
      body:
          'Der KI-Guide ist Ihr persönlicher Parkassistent. Tippen oder '
          'sprechen Sie Ihre Frage — er versteht alle fünf unterstützten '
          'Sprachen. Tippen Sie auf die Mikrofontaste zum Sprechen. Die KI '
          'kennt Ihren Standort, die Parkbedingungen und die Wanderwege.',
    ),
    _Section(
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF00BCD4),
      title: 'Tracking',
      body:
          'Der Tracking-Bildschirm zeigt Ihre Echtzeit-Wanderdaten: GPS-'
          'Koordinaten, Höhe, Geschwindigkeit, Kurs und Telefonsensoren '
          '(Akku, Schritte falls verfügbar). Er zeigt auch Ihren Wegfortschritt '
          'und die zurückgelegte Gesamtdistanz.',
    ),
    _Section(
      icon: Icons.local_parking_rounded,
      color: Color(0xFFFF5722),
      title: 'Parkplatz-Monitor',
      body:
          'Der Parkplatz-Bildschirm ermöglicht es Ihnen, Ihren Autoparkplatz '
          'mit einem Tippen zu markieren. Er speichert die GPS-Koordinaten und '
          'zeigt die Entfernung von Ihrer aktuellen Position. Nutzen Sie '
          '"Zum Auto navigieren" für die Wegbeschreibung.',
    ),
    _Section(
      icon: Icons.cloud_rounded,
      color: Color(0xFF607D8B),
      title: 'Wetter',
      body:
          'Der Wetter-Bildschirm zeigt Live-Sensordaten der Park-IoT-Stationen: '
          'Temperatur, Luftfeuchtigkeit, Luftdruck, Lärmpegel und Lichtintensität. '
          'Ein Vorhersagediagramm zeigt die erwarteten Bedingungen für die '
          'nächste Stunde.',
    ),
    _Section(
      icon: Icons.sos_rounded,
      color: Color(0xFFF44336),
      title: 'Notruf SOS',
      body:
          'Im Notfall tippen Sie auf den roten SOS-Knopf (unten rechts auf '
          'jedem Bildschirm). Halten Sie den SOS-Knopf gedrückt, um einen '
          'Alarm mit Ihren GPS-Koordinaten an die Parkranger zu senden.',
    ),
    _Section(
      icon: Icons.settings_rounded,
      color: Color(0xFF795548),
      title: 'Einstellungen',
      body:
          'Greifen Sie über den Profilavatar (oben rechts auf der Startseite) '
          'auf die Einstellungen zu. Hier können Sie Ihren Anzeigenamen '
          'aktualisieren, Benachrichtigungseinstellungen ändern und '
          'zwischengespeicherte Daten löschen.',
    ),
  ],
  'es': [
    _Section(
      icon: Icons.home_rounded,
      color: Color(0xFF4CAF50),
      title: 'Pantalla de Inicio',
      body:
          'La pantalla de inicio es tu punto de partida. Muestra las condiciones '
          'en vivo del parque (temperatura, humedad, ruido), tu estado GPS '
          '(dentro/fuera del parque) y el sendero recomendado según tus '
          'preferencias. Usa las Acciones Rápidas para acceder a cualquier '
          'función al instante.',
    ),
    _Section(
      icon: Icons.map_rounded,
      color: Color(0xFF2196F3),
      title: 'Mapa y Senderos',
      body:
          'La pantalla del Mapa muestra todos los senderos disponibles como '
          'polilíneas de colores en OpenStreetMap. Toca un marcador para '
          'previsualizarlo, luego "Iniciar Sendero" para comenzar la caminata. '
          'Tu posición GPS se muestra como un punto azul.',
    ),
    _Section(
      icon: Icons.tune_rounded,
      color: Color(0xFF9C27B0),
      title: 'Preferencias',
      body:
          'Configura tus preferencias de senderismo con los menús desplegables: '
          'dificultad, tolerancia al ruido, interés principal (historia o '
          'botánica), preferencia de pendiente, ancho del sendero, ambiente '
          'preferido e idioma de la app.',
    ),
    _Section(
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFFF9800),
      title: 'Guía IA',
      body:
          'La Guía IA es tu asistente personal del parque. Escribe o habla tu '
          'pregunta — entiende los cinco idiomas soportados. Toca el botón del '
          'micrófono para hablar. La IA conoce tu ubicación, las condiciones '
          'del parque y los senderos.',
    ),
    _Section(
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF00BCD4),
      title: 'Rastreo',
      body:
          'La pantalla de Rastreo muestra tus datos en tiempo real: coordenadas '
          'GPS, altitud, velocidad, rumbo y sensores del teléfono (batería, '
          'pasos si están disponibles). También muestra tu progreso en el '
          'sendero y la distancia total recorrida.',
    ),
    _Section(
      icon: Icons.local_parking_rounded,
      color: Color(0xFFFF5722),
      title: 'Monitor de Estacionamiento',
      body:
          'La pantalla de Estacionamiento te permite marcar el lugar de tu '
          'auto con un toque. Guarda las coordenadas GPS y muestra la distancia '
          'desde tu posición actual. Usa "Navegar al auto" para abrir las '
          'indicaciones en tu app de mapas.',
    ),
    _Section(
      icon: Icons.cloud_rounded,
      color: Color(0xFF607D8B),
      title: 'Clima',
      body:
          'La pantalla de Clima muestra datos en vivo de las estaciones IoT '
          'del parque: temperatura, humedad, presión, nivel de ruido e '
          'intensidad de luz. Un gráfico de pronóstico muestra las condiciones '
          'esperadas para la próxima hora.',
    ),
    _Section(
      icon: Icons.sos_rounded,
      color: Color(0xFFF44336),
      title: 'SOS Emergencia',
      body:
          'En una emergencia, toca el botón SOS rojo (abajo a la derecha de '
          'cada pantalla). Mantén presionado el botón SOS para enviar una '
          'alerta con tus coordenadas GPS a los guardabosques del parque.',
    ),
    _Section(
      icon: Icons.settings_rounded,
      color: Color(0xFF795548),
      title: 'Configuración',
      body:
          'Accede a Configuración desde el avatar del perfil (arriba a la '
          'derecha en Inicio). Aquí puedes actualizar tu nombre, cambiar las '
          'preferencias de notificaciones y borrar datos en caché.',
    ),
  ],
};

// ── Screen ────────────────────────────────────────────────────────────────────
class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  String _lang = 'en';
  int? _expanded;

  static const _langLabels = {
    'en': '🇬🇧 English',
    'it': '🇮🇹 Italiano',
    'fr': '🇫🇷 Français',
    'de': '🇩🇪 Deutsch',
    'es': '🇪🇸 Español',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final prefs = ref.read(preferencesProvider).valueOrNull;
      if (prefs != null && _guideContent.containsKey(prefs.language)) {
        setState(() => _lang = prefs.language);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _guideContent[_lang] ?? _guideContent['en']!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  border: Border(
                      bottom: BorderSide(color: AppColors.surfaceLight)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('App Guide',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text('HikeSilla — Parco Nazionale della Sila',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ]),
                  const Spacer(),
                  // Language selector
                  _LangDropdown(
                    value: _lang,
                    labels: _langLabels,
                    onChanged: (v) => setState(() {
                      _lang = v;
                      _expanded = null;
                    }),
                  ),
                ]),
              ),

              // ── Welcome banner ───────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primaryLight.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.forest_rounded,
                      color: AppColors.primaryLight, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Welcome to HikeSilla',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any section below to learn how to use each feature of the app.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ]),
                  ),
                ]),
              ),

              // ── Sections list ────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: sections.length,
                  itemBuilder: (_, i) => _SectionCard(
                    section: sections[i],
                    isExpanded: _expanded == i,
                    onTap: () =>
                        setState(() => _expanded = _expanded == i ? null : i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language dropdown ─────────────────────────────────────────────────────────
class _LangDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;
  const _LangDropdown(
      {required this.value, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          icon: const Icon(Icons.expand_more,
              color: AppColors.textSecondary, size: 16),
          isDense: true,
          items: labels.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _Section section;
  final bool isExpanded;
  final VoidCallback onTap;
  const _SectionCard(
      {required this.section,
      required this.isExpanded,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isExpanded
              ? section.color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? section.color.withValues(alpha: 0.4)
                : AppColors.surfaceLight,
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // ── Row header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(section.icon, color: section.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(section.title,
                      style: TextStyle(
                          color: isExpanded
                              ? section.color
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ]),
            ),
            // ── Expanded body ───────────────────────────────────────────
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    section.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
