import 'package:flutter/material.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.blueDark,
        elevation: 0,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'PlusJakartaSans',
                  color: AppColors.blueDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ultimo aggiornamento: 15 febbraio 2026',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'PlusJakartaSans',
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 24),

              _Section(
                title: '1. Titolare del trattamento',
                body:
                    'Pagella Sanremo ("l\'App") e sviluppata e gestita da Peppe Neglia. '
                    'Per qualsiasi domanda relativa alla presente informativa puoi scrivere a: '
                    'pagellasanremo@gmail.com.',
              ),

              _Section(
                title: '2. Dati raccolti',
                body:
                    'L\'App raccoglie i seguenti dati:\n\n'
                    '\u2022 Indirizzo email: necessario per la registrazione e l\'autenticazione.\n'
                    '\u2022 Username: scelto dall\'utente, visibile ai membri dei gruppi.\n'
                    '\u2022 Voti: le valutazioni assegnate agli artisti (canto, testo, look) per ciascuna serata.\n'
                    '\u2022 Gruppi: i gruppi creati o a cui l\'utente partecipa.\n\n'
                    'L\'App non raccoglie dati di geolocalizzazione, contatti, foto, '
                    'ne altre informazioni personali oltre a quelle elencate.',
              ),

              _Section(
                title: '3. Modalita anonima',
                body:
                    'E possibile utilizzare l\'App senza registrarsi. In modalita anonima '
                    'i voti vengono salvati esclusivamente sul dispositivo e nessun dato personale '
                    'viene trasmesso ai nostri server.',
              ),

              _Section(
                title: '4. Finalita del trattamento',
                body: 'I dati vengono utilizzati esclusivamente per:\n\n'
                    '\u2022 Consentire l\'accesso e il funzionamento dell\'App.\n'
                    '\u2022 Sincronizzare i voti tra dispositivi.\n'
                    '\u2022 Calcolare e visualizzare le classifiche personali, community e di gruppo.\n'
                    '\u2022 Permettere la creazione e la partecipazione ai gruppi.',
              ),

              _Section(
                title: '5. Conservazione dei dati',
                body:
                    'I dati sono conservati su server Supabase (infrastruttura cloud conforme al GDPR) '
                    'per tutta la durata di utilizzo dell\'App. L\'utente puo richiedere la cancellazione '
                    'del proprio account e di tutti i dati associati in qualsiasi momento contattando '
                    'il titolare del trattamento.',
              ),

              _Section(
                title: '6. Condivisione dei dati',
                body:
                    'I dati personali non vengono venduti, ceduti o condivisi con terze parti a fini '
                    'commerciali. I voti dell\'utente sono visibili solo ai membri dei gruppi a cui partecipa. '
                    'Le classifiche community mostrano dati aggregati e anonimi.',
              ),

              _Section(
                title: '7. Servizi di terze parti',
                body: 'L\'App utilizza i seguenti servizi:\n\n'
                    '\u2022 Supabase: per autenticazione, database e storage (https://supabase.com/privacy).\n\n'
                    'Ciascun servizio tratta i dati secondo la propria informativa sulla privacy.',
              ),

              _Section(
                title: '8. Diritti dell\'utente',
                body:
                    'Ai sensi del Regolamento UE 2016/679 (GDPR), l\'utente ha diritto di:\n\n'
                    '\u2022 Accedere ai propri dati personali.\n'
                    '\u2022 Rettificare dati inesatti.\n'
                    '\u2022 Richiedere la cancellazione dei dati.\n'
                    '\u2022 Limitare o opporsi al trattamento.\n'
                    '\u2022 Richiedere la portabilita dei dati.\n\n'
                    'Per esercitare questi diritti, contatta pagellasanremo@gmail.com.',
              ),

              _Section(
                title: '9. Sicurezza',
                body:
                    'I dati sono protetti tramite connessioni crittografate (HTTPS), politiche di accesso '
                    'a livello di riga (Row Level Security) e autenticazione sicura. '
                    'Adottiamo misure tecniche e organizzative adeguate per proteggere i tuoi dati.',
              ),

              _Section(
                title: '10. Modifiche alla Privacy Policy',
                body:
                    'La presente informativa puo essere aggiornata. In caso di modifiche significative, '
                    'l\'utente verra informato tramite l\'App. L\'uso continuato dell\'App dopo le modifiche '
                    'costituisce accettazione della nuova informativa.',
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'PlusJakartaSans',
              color: AppColors.blueDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontFamily: 'PlusJakartaSans',
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
