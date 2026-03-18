import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supported locales
// ─────────────────────────────────────────────────────────────────────────────
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('it'),
  Locale('fr'),
  Locale('de'),
  Locale('es'),
];

const Map<String, String> kLanguageNames = {
  'en': '🇬🇧 English',
  'it': '🇮🇹 Italiano',
  'fr': '🇫🇷 Français',
  'de': '🇩🇪 Deutsch',
  'es': '🇪🇸 Español',
};

// ─────────────────────────────────────────────────────────────────────────────
// Translation strings
// ─────────────────────────────────────────────────────────────────────────────
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  String get _lang => locale.languageCode;

  // ── General ───────────────────────────────────────────────────────────────
  String get appName => 'HikeSilla';
  String get ok => _t(en: 'OK', it: 'OK', fr: 'OK', de: 'OK', es: 'OK');
  String get cancel => _t(en: 'Cancel', it: 'Annulla', fr: 'Annuler', de: 'Abbrechen', es: 'Cancelar');
  String get save => _t(en: 'Save', it: 'Salva', fr: 'Enregistrer', de: 'Speichern', es: 'Guardar');
  String get loading => _t(en: 'Loading...', it: 'Caricamento...', fr: 'Chargement...', de: 'Laden...', es: 'Cargando...');
  String get error => _t(en: 'Error', it: 'Errore', fr: 'Erreur', de: 'Fehler', es: 'Error');
  String get retry => _t(en: 'Retry', it: 'Riprova', fr: 'Réessayer', de: 'Wiederholen', es: 'Reintentar');
  String get logout => _t(en: 'Logout', it: 'Esci', fr: 'Déconnexion', de: 'Abmelden', es: 'Cerrar sesión');
  String get settings => _t(en: 'Settings', it: 'Impostazioni', fr: 'Paramètres', de: 'Einstellungen', es: 'Configuración');
  String get language => _t(en: 'Language', it: 'Lingua', fr: 'Langue', de: 'Sprache', es: 'Idioma');
  String get selectLanguage => _t(en: 'Select Language', it: 'Seleziona lingua', fr: 'Choisir la langue', de: 'Sprache wählen', es: 'Seleccionar idioma');

  // ── Auth — Login ──────────────────────────────────────────────────────────
  String get welcomeBack => _t(en: 'Welcome back', it: 'Bentornato', fr: 'Bon retour', de: 'Willkommen zurück', es: 'Bienvenido de nuevo');
  String get signInSubtitle => _t(en: 'Sign in to continue your hike', it: 'Accedi per continuare la tua escursione', fr: 'Connectez-vous pour continuer', de: 'Anmelden um weiterzumachen', es: 'Inicia sesión para continuar');
  String get email => _t(en: 'Email', it: 'Email', fr: 'E-mail', de: 'E-Mail', es: 'Correo');
  String get password => _t(en: 'Password', it: 'Password', fr: 'Mot de passe', de: 'Passwort', es: 'Contraseña');
  String get signIn => _t(en: 'Sign In', it: 'Accedi', fr: 'Connexion', de: 'Anmelden', es: 'Iniciar sesión');
  String get noAccount => _t(en: "Don't have an account?", it: 'Non hai un account?', fr: 'Pas de compte?', de: 'Kein Konto?', es: '¿No tienes cuenta?');
  String get register => _t(en: 'Register', it: 'Registrati', fr: "S'inscrire", de: 'Registrieren', es: 'Registrarse');
  String get forgotPassword => _t(en: 'Forgot password?', it: 'Password dimenticata?', fr: 'Mot de passe oublié?', de: 'Passwort vergessen?', es: '¿Olvidaste tu contraseña?');
  String get enterEmail => _t(en: 'Enter your email', it: 'Inserisci la tua email', fr: 'Entrez votre e-mail', de: 'E-Mail eingeben', es: 'Ingresa tu correo');
  String get validEmail => _t(en: 'Enter a valid email', it: 'Email non valida', fr: 'E-mail invalide', de: 'Ungültige E-Mail', es: 'Correo inválido');
  String get minPassword => _t(en: 'Min 6 characters', it: 'Min 6 caratteri', fr: '6 caractères min.', de: 'Min. 6 Zeichen', es: 'Mín. 6 caracteres');
  String get securedBy => _t(en: 'Secured by Firebase Authentication · Parco della Silla 🇮🇹', it: 'Protetto da Firebase · Parco della Silla 🇮🇹', fr: 'Sécurisé par Firebase · Parco della Silla 🇮🇹', de: 'Gesichert durch Firebase · Parco della Silla 🇮🇹', es: 'Protegido por Firebase · Parco della Silla 🇮🇹');

  // ── Auth — Register ───────────────────────────────────────────────────────
  String get createAccount => _t(en: 'Create account', it: 'Crea account', fr: 'Créer un compte', de: 'Konto erstellen', es: 'Crear cuenta');
  String get joinCommunity => _t(en: 'Join the HikeSilla community', it: 'Unisciti alla comunità HikeSilla', fr: 'Rejoignez la communauté HikeSilla', de: 'Der HikeSilla-Community beitreten', es: 'Únete a la comunidad HikeSilla');
  String get yourName => _t(en: 'Your name', it: 'Il tuo nome', fr: 'Votre nom', de: 'Ihr Name', es: 'Tu nombre');
  String get enterName => _t(en: 'Enter your name', it: 'Inserisci il tuo nome', fr: 'Entrez votre nom', de: 'Namen eingeben', es: 'Ingresa tu nombre');
  String get confirmPassword => _t(en: 'Confirm password', it: 'Conferma password', fr: 'Confirmer le mot de passe', de: 'Passwort bestätigen', es: 'Confirmar contraseña');
  String get passwordsMismatch => _t(en: 'Passwords do not match', it: 'Le password non corrispondono', fr: 'Les mots de passe ne correspondent pas', de: 'Passwörter stimmen nicht überein', es: 'Las contraseñas no coinciden');
  String get alreadyAccount => _t(en: 'Already have an account?', it: 'Hai già un account?', fr: 'Déjà un compte?', de: 'Bereits ein Konto?', es: '¿Ya tienes cuenta?');
  String get accountCreated => _t(en: 'Account created! Please sign in.', it: 'Account creato! Effettua il login.', fr: 'Compte créé! Connectez-vous.', de: 'Konto erstellt! Bitte anmelden.', es: '¡Cuenta creada! Inicia sesión.');
  String get prefsInfo => _t(en: 'After registering, set your hiking preferences and our AI will recommend the best trails.', it: 'Dopo la registrazione imposta le tue preferenze e la nostra IA ti consiglierà i migliori sentieri.', fr: 'Après inscription, définissez vos préférences et notre IA vous recommandera les meilleurs sentiers.', de: 'Nach der Registrierung stellen Sie Ihre Präferenzen ein und unsere KI empfiehlt die besten Routen.', es: 'Tras registrarte, configura tus preferencias y nuestra IA te recomendará los mejores senderos.');

  // ── Password Reset ────────────────────────────────────────────────────────
  String get resetPassword => _t(en: 'Reset Password', it: 'Reimposta password', fr: 'Réinitialiser le mot de passe', de: 'Passwort zurücksetzen', es: 'Restablecer contraseña');
  String get resetSubtitle => _t(en: "Enter your email and we'll send you a reset link.", it: 'Inserisci la tua email e ti invieremo un link di reimpostazione.', fr: 'Entrez votre e-mail et nous vous enverrons un lien de réinitialisation.', de: 'Geben Sie Ihre E-Mail ein und wir senden Ihnen einen Reset-Link.', es: 'Ingresa tu correo y te enviaremos un enlace para restablecer.');
  String get sendResetLink => _t(en: 'Send Reset Link', it: 'Invia link di reset', fr: 'Envoyer le lien', de: 'Reset-Link senden', es: 'Enviar enlace');
  String get resetEmailSent => _t(en: 'Reset email sent! Check your inbox.', it: 'Email inviata! Controlla la tua casella.', fr: 'E-mail envoyé! Vérifiez votre boîte.', de: 'E-Mail gesendet! Prüfen Sie Ihren Posteingang.', es: '¡Correo enviado! Revisa tu bandeja.');
  String get backToLogin => _t(en: 'Back to Login', it: 'Torna al login', fr: 'Retour à la connexion', de: 'Zurück zur Anmeldung', es: 'Volver al inicio de sesión');

  // ── Home ──────────────────────────────────────────────────────────────────
  String get hello => _t(en: 'Hello', it: 'Ciao', fr: 'Bonjour', de: 'Hallo', es: 'Hola');
  String get parkName => _t(en: 'Parco Nazionale della Sila', it: 'Parco Nazionale della Sila', fr: 'Parc National de la Sila', de: 'Nationalpark Sila', es: 'Parque Nacional de la Sila');
  String get liveConditions => _t(en: 'Live Conditions', it: 'Condizioni live', fr: 'Conditions en direct', de: 'Live-Bedingungen', es: 'Condiciones en vivo');
  String get recommendedTrail => _t(en: 'Recommended Trail', it: 'Sentiero consigliato', fr: 'Sentier recommandé', de: 'Empfohlener Pfad', es: 'Sendero recomendado');
  String get yourLocation => _t(en: 'Your Location', it: 'La tua posizione', fr: 'Votre position', de: 'Ihr Standort', es: 'Tu ubicación');
  String get tracking => _t(en: 'Tracking', it: 'Tracciamento', fr: 'Suivi', de: 'Tracking', es: 'Rastreo');
  String get noData => _t(en: 'No data available', it: 'Nessun dato disponibile', fr: 'Aucune donnée disponible', de: 'Keine Daten verfügbar', es: 'Sin datos disponibles');

  // ── Navigation ────────────────────────────────────────────────────────────
  String get navHome => _t(en: 'Home', it: 'Home', fr: 'Accueil', de: 'Start', es: 'Inicio');
  String get navMap => _t(en: 'Map', it: 'Mappa', fr: 'Carte', de: 'Karte', es: 'Mapa');
  String get navWeather => _t(en: 'Weather', it: 'Meteo', fr: 'Météo', de: 'Wetter', es: 'Clima');
  String get navAI => _t(en: 'AI Guide', it: 'Guida IA', fr: 'Guide IA', de: 'KI-Guide', es: 'Guía IA');
  String get navPrefs => _t(en: 'Prefs', it: 'Preferenze', fr: 'Préfs', de: 'Einst.', es: 'Prefs');

  // ── Weather ───────────────────────────────────────────────────────────────
  String get temperature => _t(en: 'Temperature', it: 'Temperatura', fr: 'Température', de: 'Temperatur', es: 'Temperatura');
  String get humidity => _t(en: 'Humidity', it: 'Umidità', fr: 'Humidité', de: 'Luftfeuchtigkeit', es: 'Humedad');
  String get pressure => _t(en: 'Pressure', it: 'Pressione', fr: 'Pression', de: 'Luftdruck', es: 'Presión');
  String get noiseLevel => _t(en: 'Noise Level', it: 'Livello rumore', fr: 'Niveau sonore', de: 'Lärmpegel', es: 'Nivel de ruido');
  String get weatherForecast => _t(en: 'Weather Forecast', it: 'Previsioni meteo', fr: 'Prévisions météo', de: 'Wettervorhersage', es: 'Pronóstico');
  String get noStationNow => _t(en: 'No sub-station now', it: 'Nessuna stazione attiva', fr: 'Aucune station active', de: 'Keine Station aktiv', es: 'Sin estación activa');

  // ── Map / Trails ──────────────────────────────────────────────────────────
  String get trails => _t(en: 'Trails', it: 'Sentieri', fr: 'Sentiers', de: 'Wanderwege', es: 'Senderos');
  String get difficulty => _t(en: 'Difficulty', it: 'Difficoltà', fr: 'Difficulté', de: 'Schwierigkeit', es: 'Dificultad');
  String get distance => _t(en: 'Distance', it: 'Distanza', fr: 'Distance', de: 'Entfernung', es: 'Distancia');
  String get duration => _t(en: 'Duration', it: 'Durata', fr: 'Durée', de: 'Dauer', es: 'Duración');
  String get elevation => _t(en: 'Elevation', it: 'Elevazione', fr: 'Élévation', de: 'Höhe', es: 'Elevación');
  String get easy => _t(en: 'Easy', it: 'Facile', fr: 'Facile', de: 'Leicht', es: 'Fácil');
  String get moderate => _t(en: 'Moderate', it: 'Moderato', fr: 'Modéré', de: 'Mittel', es: 'Moderado');
  String get hard => _t(en: 'Hard', it: 'Difficile', fr: 'Difficile', de: 'Schwer', es: 'Difícil');

  // ── Preferences ───────────────────────────────────────────────────────────
  String get hikerPreferences => _t(en: 'Hiker Preferences', it: 'Preferenze escursionista', fr: 'Préférences randonneur', de: 'Wanderer-Einstellungen', es: 'Preferencias del senderista');
  String get savePreferences => _t(en: 'Save Preferences', it: 'Salva preferenze', fr: 'Enregistrer les préférences', de: 'Einstellungen speichern', es: 'Guardar preferencias');
  String get preferencesSaved => _t(en: 'Preferences saved!', it: 'Preferenze salvate!', fr: 'Préférences enregistrées!', de: 'Einstellungen gespeichert!', es: '¡Preferencias guardadas!');

  // ── Chatbot ───────────────────────────────────────────────────────────────
  String get aiGuide => _t(en: 'AI Park Guide', it: 'Guida IA del Parco', fr: 'Guide IA du Parc', de: 'KI-Parkführer', es: 'Guía IA del Parque');
  String get typeMessage => _t(en: 'Ask about the park...', it: 'Chiedi informazioni sul parco...', fr: 'Posez une question sur le parc...', de: 'Fragen Sie zum Park...', es: 'Pregunta sobre el parque...');

  // ── SOS ───────────────────────────────────────────────────────────────────
  String get emergency => _t(en: 'Emergency', it: 'Emergenza', fr: 'Urgence', de: 'Notfall', es: 'Emergencia');
  String get sosTitle => _t(en: 'Emergency SOS', it: 'SOS Emergenza', fr: "SOS d'urgence", de: 'Notfall SOS', es: 'SOS de emergencia');
  String get sosSubtitle => _t(en: 'Hold the button to send an emergency alert', it: 'Tieni premuto il pulsante per inviare un allarme', fr: "Maintenez le bouton pour envoyer une alerte", de: 'Halten Sie die Taste zum Senden eines Alarms gedrückt', es: 'Mantén el botón para enviar una alerta de emergencia');

  // ─── Helper ───────────────────────────────────────────────────────────────
  String _t({
    required String en,
    required String it,
    required String fr,
    required String de,
    required String es,
  }) {
    switch (_lang) {
      case 'it': return it;
      case 'fr': return fr;
      case 'de': return de;
      case 'es': return es;
      default:   return en;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delegate
// ─────────────────────────────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.map((l) => l.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}

// Extension with extra strings used in home & settings
extension AppLocalizationsExtra on AppLocalizations {
  String get quickActions => _t(en: 'Quick Actions', it: 'Azioni rapide', fr: 'Actions rapides', de: 'Schnellaktionen', es: 'Acciones rápidas');
  String get fromFirestore => _t(en: 'From Firestore · matched to your prefs', it: 'Da Firestore · adattato alle tue preferenze', fr: 'Depuis Firestore · adapté à vos préférences', de: 'Aus Firestore · abgestimmt auf Ihre Prefs', es: 'De Firestore · adaptado a tus preferencias');
  String get allTrails => _t(en: 'All trails', it: 'Tutti i sentieri', fr: 'Tous les sentiers', de: 'Alle Pfade', es: 'Todos los senderos');
  String get youAreHiking => _t(en: 'You are hiking!', it: 'Stai facendo escursionismo!', fr: 'Vous randonnez!', de: 'Sie wandern!', es: '¡Estás senderando!');
  String get readyToHike => _t(en: 'Ready to hike?', it: 'Pronto per l\'escursione?', fr: 'Prêt à randonner?', de: 'Bereit zum Wandern?', es: '¿Listo para senderear?');
  String get locationShared => _t(en: 'Your location is being shared with park rangers', it: 'La tua posizione viene condivisa con i ranger', fr: 'Votre position est partagée avec les gardes', de: 'Ihr Standort wird mit Rangern geteilt', es: 'Tu ubicación se comparte con los guardabosques');
  String get talkToGuide => _t(en: 'Talk to your AI guide to plan your next adventure', it: 'Parla con la guida IA per pianificare la tua avventura', fr: 'Parlez à votre guide IA pour planifier votre aventure', de: 'Sprechen Sie mit Ihrem KI-Guide', es: 'Habla con tu guía IA para planear tu aventura');
  String get insidePark => _t(en: 'Inside Park', it: 'Nel Parco', fr: 'Dans le Parc', de: 'Im Park', es: 'Dentro del Parque');
  String get outsidePark => _t(en: 'Outside Park', it: 'Fuori dal Parco', fr: 'Hors du Parc', de: 'Außerhalb des Parks', es: 'Fuera del Parque');
  String get settingsSubtitle => _t(en: 'Language, profile & app settings', it: 'Lingua, profilo e impostazioni app', fr: 'Langue, profil et paramètres', de: 'Sprache, Profil und App-Einstellungen', es: 'Idioma, perfil y configuración');
  String get prefsSubtitle => _t(en: 'Update hiking preferences & AI settings', it: 'Aggiorna preferenze escursionismo e IA', fr: 'Mettre à jour les préférences et l\'IA', de: 'Wanderpräferenzen und KI-Einstellungen', es: 'Actualizar preferencias de senderismo e IA');
  String get logoutSubtitle => _t(en: 'Sign out of your account', it: 'Esci dal tuo account', fr: 'Se déconnecter du compte', de: 'Vom Konto abmelden', es: 'Cerrar sesión en tu cuenta');
  String get profile => _t(en: 'Profile', it: 'Profilo', fr: 'Profil', de: 'Profil', es: 'Perfil');
  String get weatherTitle => _t(en: 'Weather', it: 'Meteo', fr: 'Météo', de: 'Wetter', es: 'Clima');
  String get parkConditions => _t(en: 'Park Conditions', it: 'Condizioni del parco', fr: 'Conditions du parc', de: 'Parkbedingungen', es: 'Condiciones del parque');
  String get liveIoT => _t(en: 'Live IoT Sensors', it: 'Sensori IoT live', fr: 'Capteurs IoT en direct', de: 'Live IoT-Sensoren', es: 'Sensores IoT en vivo');
  String get mapTitle => _t(en: 'Trail Map', it: 'Mappa dei sentieri', fr: 'Carte des sentiers', de: 'Wanderkarte', es: 'Mapa de senderos');
  String get chatbotTitle => _t(en: 'AI Park Guide', it: 'Guida IA del Parco', fr: 'Guide IA du Parc', de: 'KI-Parkführer', es: 'Guía IA del Parque');
  String get sosButton => _t(en: 'Hold to send SOS', it: 'Tieni premuto per SOS', fr: 'Maintenir pour envoyer SOS', de: 'Halten zum SOS senden', es: 'Mantener para enviar SOS');
  String get prefsTitle => _t(en: 'Hiker Preferences', it: 'Preferenze escursionista', fr: 'Préférences randonneur', de: 'Wandererpräferenzen', es: 'Preferencias del senderista');
}
