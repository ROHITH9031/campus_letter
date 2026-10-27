import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:file_saver/file_saver.dart';

void main() => runApp(const CampusLetterApp());

class CampusLetterApp extends StatelessWidget {
  const CampusLetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Letter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF174EA6)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const LetterHomePage(),
    );
  }
}

enum LetterType { languageNest, normal }

class EventDetails {
  String date = '';
  String eventName = '';
  String eventDate = '';
  String studentOrganizers = '';
  String eventDescription = '';
  String teamName = '';
}

class NormalLetterDetails {
  String date = '';
  String recipient = '';
  String institution = '';
  String subject = '';
  String salutation = '';
  String message = '';
  String senderName = '';
}

class SavedLetter {
  const SavedLetter({
    required this.id,
    required this.type,
    required this.content,
  });

  final String id;
  final LetterType type;
  final String content;
}

class LetterHomePage extends StatefulWidget {
  const LetterHomePage({super.key});

  @override
  State<LetterHomePage> createState() => _LetterHomePageState();
}

class _LetterHomePageState extends State<LetterHomePage> {
  final event = EventDetails();
  final normal = NormalLetterDetails();
  final savedLetters = <SavedLetter>[];
  final _formKey = GlobalKey<FormState>();
  LetterType selectedType = LetterType.languageNest;
  int tabIndex = 0;
  bool loadingSavedLetters = false;

static final _apiBaseUrl = Uri.parse(
  const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://campus-letter.onrender.com',
  ),
);

  @override
  void initState() {
    super.initState();
    _loadSavedLetters();
  }

  String get languageNestLetter {
    final date = _value(event.date, '30/09/2026');
    final eventName = _value(event.eventName, 'Branch Perspective');
    final eventDate = _value(event.eventDate, date);
    final organizers = _value(
      event.studentOrganizers,
      'the student organizers',
    );
    final description = _value(
      event.eventDescription,
      'to help students understand branch-related opportunities, develop practical skills, explore higher education options, and make informed decisions about their career prospects',
    );
    final team = _value(event.teamName, 'Team Language Nest');
    return '''Date: $date

To
Dean - Academics
SRKR Engineering College
Bhimavaram.

Subject: Request for Attendance to organising the $eventName Event.

Respected Sir,

We, the members of Language Nest Club, are organizing the “$eventName” event $description. The programme is intended to give students a meaningful opportunity to learn from one another, interact with experienced participants, and gain a clearer understanding of the academic and professional opportunities available to them.

We kindly request you to grant attendance permission to $organizers on $eventDate. Their presence is required for the planning, coordination, preparation of the venue and materials, welcoming the participants, and successful execution of the event. The organizers will ensure that their academic responsibilities are managed properly and that the programme is conducted in an orderly manner.

We request your kind approval and support for this student-led initiative. Your permission will encourage the students to participate actively in co-curricular activities and will help us conduct the event with the required discipline and responsibility.

Yours Sincerely,
$team
SRKR Engineering College''';
  }

  String get normalLetter {
    final date = _value(normal.date, 'Date');
    final recipient = _value(normal.recipient, 'Recipient name');
    final institution = _value(normal.institution, 'Institution name');
    final subject = _value(normal.subject, 'Letter subject');
    final message = _enhanceNormalMessage(
      subject: subject,
      message: normal.message,
    );
    final salutation = _value(normal.salutation, 'Respected Sir/Madam,');
    final sender = _value(normal.senderName, 'Your name');
    return '''Date: $date

To
$recipient
$institution

Subject: $subject

$salutation

$message

Yours Sincerely,
$sender''';
  }

  String _enhanceNormalMessage({
    required String subject,
    required String message,
  }) {
    final original = message.trim();
    final normalizedSubject = subject.trim().toLowerCase();
    final keywords = '$normalizedSubject ${original.toLowerCase()}';
    final hasSpecificSubject =
        normalizedSubject.isNotEmpty && normalizedSubject != 'letter subject';
    final paragraphs = <String>[
      if (original.isEmpty)
        'I am writing to respectfully request your kind consideration regarding the matter mentioned above. I request your support because this approval will help me complete the required academic or administrative work responsibly and within the given time.'
      else
        original,
    ];

    if (_containsAny(keywords, ['attendance', 'absent', 'absence'])) {
      paragraphs.add(
        'I kindly request that the relevant attendance record be considered for the specified period. I will make every effort to attend future classes regularly, cover the lessons missed, and complete all academic responsibilities without delay.',
      );
    } else if (_containsAny(keywords, [
      'leave',
      'holiday',
      'medical',
      'health',
    ])) {
      paragraphs.add(
        'I request leave for the necessary period and will ensure that any missed lessons, assignments, or departmental requirements are completed promptly after my return. I will also provide supporting documents if they are required by the institution.',
      );
    } else if (hasSpecificSubject &&
        _containsAny(keywords, [
          'permission',
          'approval',
          'allow',
          'consent',
        ])) {
      paragraphs.add(
        'I kindly request you to review the circumstances and grant the necessary permission. I assure you that I will follow the approved procedure, comply with all applicable college rules, and complete any conditions associated with this request.',
      );
    }

    if (_containsAny(keywords, [
      'event',
      'programme',
      'program',
      'workshop',
      'seminar',
      'club',
    ])) {
      paragraphs.add(
        'The activity will be conducted in an orderly and responsible manner. I will coordinate with the concerned department, follow the approved schedule, and ensure that the programme does not adversely affect academic work or institutional discipline.',
      );
    } else if (_containsAny(keywords, [
      'exam',
      'examination',
      'test',
      'internal',
      'semester',
    ])) {
      paragraphs.add(
        'I understand the importance of the academic schedule and will comply with the examination rules and instructions issued by the college. I will complete the required academic preparation and documentation within the permitted time.',
      );
    } else if (_containsAny(keywords, [
      'certificate',
      'bonafide',
      'document',
      'transcript',
    ])) {
      paragraphs.add(
        'I have provided the necessary information for verification and will submit any additional documents or details required by the concerned office. I would be grateful if the request could be processed at your earliest convenience.',
      );
    } else if (_containsAny(keywords, [
      'fee',
      'fees',
      'scholarship',
      'financial',
      'payment',
    ])) {
      paragraphs.add(
        'I request your guidance regarding the applicable financial procedure and any supporting documents that must be submitted. I will comply with the instructions of the accounts or scholarship section and complete the process within the permitted time.',
      );
    }

    if (original.isNotEmpty || hasSpecificSubject) {
      paragraphs.add(
        "I assure you that I will cooperate fully with the concerned department, respect the institution's procedures, and complete all pending responsibilities. Your support and consideration will be highly appreciated.",
      );
    }

    return paragraphs.join('\n\n');
  }

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any(text.contains);

  String get currentLetter => selectedType == LetterType.languageNest
      ? languageNestLetter
      : normalLetter;

  String _value(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Letter'),
        actions: [
          IconButton(
            tooltip: 'Event details',
            onPressed: _openDetails,
            icon: const Icon(Icons.event_note_outlined),
          ),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: [_buildHome(), _buildEditor(), _buildSaved()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) => setState(() => tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Create your letter',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose one of the two letter formats to get started.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _letterTypeCard(
          type: LetterType.languageNest,
          title: 'Language Nest Letter',
          subtitle: 'Event attendance request in the Language Nest format',
          icon: Icons.language,
        ),
        _letterTypeCard(
          type: LetterType.normal,
          title: 'Normal Letter',
          subtitle: 'A clean standard page for any campus request',
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.event_note_outlined)),
            title: const Text('Add event details'),
            subtitle: const Text(
              'Enter the date, event name, organizers, and event description.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openDetails,
          ),
        ),
      ],
    );
  }

  Widget _letterTypeCard({
    required LetterType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = selectedType == type;
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(selected ? Icons.check_circle : Icons.arrow_forward_ios),
        onTap: () {
          setState(() {
            selectedType = type;
            tabIndex = 1;
          });
        },
      ),
    );
  }

  Widget _buildEditor() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          selectedType == LetterType.languageNest
              ? 'Language Nest Letter'
              : 'Normal Letter',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          selectedType == LetterType.languageNest
              ? 'Fill in the event details used in the reference format.'
              : 'Fill in the details for a standard letter page.',
        ),
        const SizedBox(height: 20),
        SegmentedButton<LetterType>(
          segments: const [
            ButtonSegment(
              value: LetterType.languageNest,
              label: Text('Language Nest'),
              icon: Icon(Icons.language),
            ),
            ButtonSegment(
              value: LetterType.normal,
              label: Text('Normal Letter'),
              icon: Icon(Icons.description_outlined),
            ),
          ],
          selected: {selectedType},
          onSelectionChanged: (selection) =>
              setState(() => selectedType = selection.first),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selectedType == LetterType.languageNest
                        ? 'Event details'
                        : 'Letter details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedType == LetterType.languageNest)
                    ..._languageNestFields()
                  else
                    ..._normalFields(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _showPreview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Preview letter'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _saveLetter,
          icon: const Icon(Icons.bookmark_border),
          label: const Text('Save letter'),
        ),
      ],
    );
  }

  List<Widget> _languageNestFields() {
    return [
      _textField(
        label: 'Date',
        hint: '30/09/2026',
        initialValue: event.date,
        onChanged: (value) => event.date = value,
        dateField: true,
      ),
      _textField(
        label: 'Event name',
        hint: 'Branch Perspective',
        initialValue: event.eventName,
        onChanged: (value) => event.eventName = value,
      ),
      _textField(
        label: 'Event date',
        hint: '30-09-2026',
        initialValue: event.eventDate,
        onChanged: (value) => event.eventDate = value,
        dateField: true,
      ),
      _textField(
        label: 'Student organizers',
        hint: 'Names or group of student organizers',
        initialValue: event.studentOrganizers,
        onChanged: (value) => event.studentOrganizers = value,
      ),
      _textField(
        label: 'Event description',
        hint: 'Purpose and details of the event',
        initialValue: event.eventDescription,
        maxLines: 4,
        onChanged: (value) => event.eventDescription = value,
      ),
      _textField(
        label: 'Team name',
        hint: 'Team Language Nest',
        initialValue: event.teamName,
        onChanged: (value) => event.teamName = value,
      ),
    ];
  }

  List<Widget> _normalFields() {
    return [
      _textField(
        label: 'Date',
        hint: 'Date of the letter',
        initialValue: normal.date,
        onChanged: (value) => normal.date = value,
        dateField: true,
      ),
      _textField(
        label: 'To',
        hint: 'Recipient name or designation',
        initialValue: normal.recipient,
        onChanged: (value) => normal.recipient = value,
      ),
      _textField(
        label: 'Institution',
        hint: 'College or department',
        initialValue: normal.institution,
        onChanged: (value) => normal.institution = value,
      ),
      _textField(
        label: 'Subject',
        hint: 'Subject of the letter',
        initialValue: normal.subject,
        onChanged: (value) => normal.subject = value,
      ),
      _textField(
        label: 'Salutation',
        hint: 'Respected Sir/Madam,',
        initialValue: normal.salutation,
        onChanged: (value) => normal.salutation = value,
      ),
      _textField(
        label: 'Letter message',
        hint: 'Write your letter message',
        initialValue: normal.message,
        maxLines: 7,
        onChanged: (value) => normal.message = value,
      ),
      _textField(
        label: 'Yours sincerely - name',
        hint: 'Your name',
        initialValue: normal.senderName,
        onChanged: (value) => normal.senderName = value,
      ),
    ];
  }

  Widget _textField({
    required String label,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool dateField = false,
  }) {
    if (dateField) {
      return _dateField(
        label: label,
        hint: hint,
        initialValue: initialValue,
        onChanged: onChanged,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: _requiredValidator,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: TextEditingController(text: initialValue),
        readOnly: true,
        onTap: () => _selectDate(onChanged),
        validator: _requiredValidator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _selectDate(ValueChanged<String> onChanged) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (selected == null) return;
    final formatted =
        '${selected.day.toString().padLeft(2, '0')}/'
        '${selected.month.toString().padLeft(2, '0')}/'
        '${selected.year}';
    setState(() => onChanged(formatted));
  }

  Widget _buildSaved() {
    if (loadingSavedLetters) {
      return const Center(child: CircularProgressIndicator());
    }
    if (savedLetters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No saved letters yet.\nCreate a letter and save it here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: savedLetters.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text('Saved ${index + 1}'),
          subtitle: Text(
            savedLetters[index].type == LetterType.languageNest
                ? 'Language Nest Letter'
                : 'Normal Letter',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _showLetter(savedLetters[index].content),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLetter() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _message('Please fill in all required fields.');
      return;
    }
    try {
      final response = await http
          .post(
            _apiBaseUrl.replace(path: '${_apiBaseUrl.path}/letters'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_letterPayload()),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 201) {
        throw Exception('API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final saved = data['data'] as Map<String, dynamic>?;
      final id = saved?['id'] as String?;
      if (id == null || id.isEmpty) {
        throw Exception('API response did not include a letter id');
      }
      if (!mounted) return;
      setState(() {
        savedLetters.removeWhere((letter) => letter.content == currentLetter);
        savedLetters.insert(
          0,
          SavedLetter(id: id, type: selectedType, content: currentLetter),
        );
      });
      _message('Letter saved.');
    } catch (error) {
      if (mounted) {
        _message('Could not save letter to the backend: $error');
      }
    }
  }

  Map<String, String> _letterPayload() {
    if (selectedType == LetterType.languageNest) {
      return {
        'type': 'languageNest',
        'date': event.date,
        'eventName': event.eventName,
        'eventDate': event.eventDate,
        'studentOrganizers': event.studentOrganizers,
        'eventDescription': event.eventDescription,
        'teamName': event.teamName,
      };
    }
    return {
      'type': 'normal',
      'date': normal.date,
      'recipient': normal.recipient,
      'institution': normal.institution,
      'subject': normal.subject,
      'salutation': normal.salutation,
      'message': normal.message,
      'senderName': normal.senderName,
    };
  }

  Future<void> _loadSavedLetters() async {
    setState(() => loadingSavedLetters = true);
    try {
      final response = await http
          .get(_apiBaseUrl.replace(path: '${_apiBaseUrl.path}/letters'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('API returned status ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      final loaded = data.map((item) {
        final record = item as Map<String, dynamic>;
        final type = (record['type'] as String?) == 'languageNest'
            ? LetterType.languageNest
            : LetterType.normal;
        final details = Map<String, dynamic>.from(
          record['details'] as Map<dynamic, dynamic>? ?? {},
        );
        return SavedLetter(
          id: record['id'] as String,
          type: type,
          content: _letterFromDetails(type, details),
        );
      }).toList();
      if (mounted) {
        setState(() {
          savedLetters
            ..clear()
            ..addAll(loaded);
          loadingSavedLetters = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => loadingSavedLetters = false);
        _message('Could not load saved letters from the backend: $error');
      }
    }
  }

  String _letterFromDetails(LetterType type, Map<String, dynamic> details) {
    if (type == LetterType.languageNest) {
      event
        ..date = details['date'] as String? ?? ''
        ..eventName = details['eventName'] as String? ?? ''
        ..eventDate = details['eventDate'] as String? ?? ''
        ..studentOrganizers = details['studentOrganizers'] as String? ?? ''
        ..eventDescription = details['eventDescription'] as String? ?? ''
        ..teamName = details['teamName'] as String? ?? '';
      return languageNestLetter;
    }
    normal
      ..date = details['date'] as String? ?? ''
      ..recipient = details['recipient'] as String? ?? ''
      ..institution = details['institution'] as String? ?? ''
      ..subject = details['subject'] as String? ?? ''
      ..salutation = details['salutation'] as String? ?? ''
      ..message = details['message'] as String? ?? ''
      ..senderName = details['senderName'] as String? ?? '';
    return normalLetter;
  }

  Future<void> _copyLetter(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _message('Letter copied to clipboard.');
  }

  Future<void> _downloadLetter(String text) async {
    final typeName = selectedType == LetterType.languageNest
        ? 'language_nest'
        : 'normal';
    final date = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final content = await _letterHtml(
        text,
        includeLanguageNestHeader: selectedType == LetterType.languageNest,
      );
      await FileSaver.instance.saveFile(
        name: 'campus_letter_${typeName}_$date',
        bytes: Uint8List.fromList(utf8.encode(content)),
        ext: 'html',
        mimeType: MimeType.custom,
        customMimeType: 'text/html',
      );
      if (mounted) _message('Letter downloaded successfully.');
    } catch (error) {
      if (mounted) _message('Download failed: $error');
    }
  }

  Future<String> _letterHtml(
    String text, {
    required bool includeLanguageNestHeader,
  }) async {
    final image = await rootBundle.load(
      'images/Screenshot_2026_1027_133843.png',
    );
    final imageBase64 = base64Encode(image.buffer.asUint8List());
    final escapedText = _escapeHtml(text);
    return '''<!doctype html>
<html>
<head><meta charset="utf-8"><title>${includeLanguageNestHeader ? 'Language Nest' : 'Normal'} Letter</title>
<style>
@page { size: A4; margin: 0; }
body { margin: 0; background: #f3f4f6; font-family: Georgia, "Times New Roman", serif; }
.page { position: relative; overflow: hidden; max-width: 860px; min-height: 1100px; margin: 24px auto; padding: 34px 46px; background: white; border: 1px solid #444; box-sizing: border-box; }
.template { position: absolute; z-index: 0; inset: 0; width: 100%; height: 100%; object-fit: cover; object-position: center; opacity: .04; }
.header { position: relative; z-index: 1; width: 100%; max-height: 170px; object-fit: cover; object-position: top; }
.letter { position: relative; z-index: 1; white-space: pre-wrap; margin-top: 24px; font-size: 16px; line-height: 1.55; color: #111; }
</style></head>
<body><main class="page">
${includeLanguageNestHeader ? '<img class="header" src="data:image/png;base64,$imageBase64" alt="Language Nest and college logos">' : ''}
${includeLanguageNestHeader ? '<img class="template" src="data:image/png;base64,$imageBase64" alt="">' : ''}
<div class="letter">$escapedText</div>
</main></body></html>''';
  }

  String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  void _showPreview() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _message('Please fill in all required fields.');
      return;
    }
    _showLetter(currentLetter);
  }

  void _showLetter(String text) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  selectedType == LetterType.languageNest
                      ? 'Language Nest preview'
                      : 'Normal letter preview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _LetterPage(
                  text: text,
                  showHeader: selectedType == LetterType.languageNest,
                  showWatermark: selectedType == LetterType.languageNest,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _downloadLetter(text),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Download'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyLetter(text),
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails() async {
    if (selectedType == LetterType.languageNest) {
      setState(() => tabIndex = 1);
    } else {
      setState(() => tabIndex = 1);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LetterPage extends StatelessWidget {
  const _LetterPage({
    required this.text,
    required this.showHeader,
    required this.showWatermark,
  });

  final String text;
  final bool showHeader;
  final bool showWatermark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade600),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (showWatermark)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.04,
                  child: Transform.translate(
                    offset: const Offset(0, -150),
                    child: Image.asset(
                      'images/Screenshot_2026_1027_133843.png',
                      fit: BoxFit.fill,
                      height: 900,
                      width: double.infinity,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader)
                  ClipRect(
                    child: SizedBox(
                      height: 132,
                      child: Image.asset(
                        'images/Screenshot_2026_1027_133843.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                if (showHeader) ...[const SizedBox(height: 24)],
                SelectableText(
                  text,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
