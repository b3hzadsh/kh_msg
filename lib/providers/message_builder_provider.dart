import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_message_models.dart';

class MessageBuilderProvider extends ChangeNotifier {
  MessageBuilderProvider({MessageGenerator? generator})
    : _generator = generator ?? MessageGenerator();

  static const String _kSenderTitleKey = 'fixed_sender_title';
  static const String _kOrgTitleKey = 'fixed_org_title';

  final MessageGenerator _generator;

  bool _isInitialized = false;
  String _senderTitle = '';
  String _orgTitle = '';

  CourseType _selectedCourse = CourseType.courseA;
  int _selectedSession = 1;
  String _currentQuote = MessageGenerator.quotes.first;
  List<String> _usedQuotes = [MessageGenerator.quotes.first];
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  String get senderTitle => _senderTitle;
  String get orgTitle => _orgTitle;
  bool get hasProfile =>
      _senderTitle.trim().isNotEmpty && _orgTitle.trim().isNotEmpty;

  CourseType get selectedCourse => _selectedCourse;
  int get totalSessionsInSelectedCourse => _selectedCourse.spec.totalSessions;
  int get selectedSession => _selectedSession;
  bool get isLastSession => _selectedSession == totalSessionsInSelectedCourse;

  String? get selectedSessionLink =>
      _selectedCourse.spec.linkForSession(_selectedSession);
  String get currentQuote => _currentQuote;
  String? get errorMessage => _errorMessage;

  String? get generatedMessage {
    if (!hasProfile) {
      return null;
    }
    try {
      return _generator.buildFinalMessage(
        senderTitle: _senderTitle,
        orgTitle: _orgTitle,
        quote: _currentQuote,
        course: _selectedCourse,
        sessionNumber: _selectedSession,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _senderTitle = prefs.getString(_kSenderTitleKey)?.trim() ?? '';
    _orgTitle = prefs.getString(_kOrgTitleKey)?.trim() ?? '';

    final picked = _generator.pickQuote(const []);
    _currentQuote = picked.$1;
    _usedQuotes = picked.$2;

    _selectedSession = 1;
    _errorMessage = null;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveProfile({
    required String senderTitle,
    required String orgTitle,
  }) async {
    final cleanSender = senderTitle.trim();
    final cleanOrg = orgTitle.trim();

    if (cleanSender.isEmpty || cleanOrg.isEmpty) {
      _errorMessage = 'هر دو بخش عنوان ثابت و نام مجموعه باید وارد شوند.';
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSenderTitleKey, cleanSender);
    await prefs.setString(_kOrgTitleKey, cleanOrg);

    _senderTitle = cleanSender;
    _orgTitle = cleanOrg;
    _errorMessage = null;
    notifyListeners();
  }

  void selectCourse(CourseType course) {
    if (_selectedCourse == course) return;
    _selectedCourse = course;
    _selectedSession = 1;
    _errorMessage = null;
    notifyListeners();
  }

  void selectSession(int sessionNumber) {
    final maxSessions = _selectedCourse.spec.totalSessions;
    if (sessionNumber < 1 || sessionNumber > maxSessions) {
      _errorMessage = 'شماره جلسه باید بین ۱ تا $maxSessions باشد.';
      notifyListeners();
      return;
    }
    _selectedSession = sessionNumber;
    _errorMessage = null;
    notifyListeners();
  }

  void rerollQuote() {
    final picked = _generator.pickQuote(_usedQuotes);
    _currentQuote = picked.$1;
    _usedQuotes = picked.$2;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
