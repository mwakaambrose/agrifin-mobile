import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../data/api/constitution_api_repository.dart';
import '../data/constitution_repository.dart';

enum SectionKind { generic, savings, loans, socialFund, fines }

/// Simple section model for the constitution
class ConstitutionSection {
  final String id;
  String title;
  String body;
  final SectionKind kind;
  Map<String, dynamic> settings; // structured settings for special kinds
  ConstitutionSection({
    required this.id,
    required this.title,
    required this.body,
    this.kind = SectionKind.generic,
    Map<String, dynamic>? settings,
  }) : settings = settings ?? {};

  ConstitutionSection copyWith({
    String? title,
    String? body,
    Map<String, dynamic>? settings,
  }) => ConstitutionSection(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    kind: kind,
    settings: settings ?? Map<String, dynamic>.from(this.settings),
  );
}

/// ViewModel handling constitution state & mutations
class ConstitutionViewModel extends ChangeNotifier {
  final ConstitutionRepository _repo;
  final ConstitutionApiRepository _api = ConstitutionApiRepository();
  ConstitutionViewModel(this._repo) {
    _init();
  }

  final List<ConstitutionSection> _sections = [];
  bool _loading = false;
  String? _error;
  bool _locked = false;

  List<ConstitutionSection> get sections => List.unmodifiable(_sections);
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isEmpty => _sections.isEmpty;
  bool get isLocked => _locked;

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      _locked = await _repo.isLocked();
      final loaded = await _repo.loadSections();
      if (loaded.isEmpty) {
        // seed default sections (only if nothing stored yet)
        _sections.addAll([
          ConstitutionSection(
            id: '1',
            title: 'Group Name & Purpose',
            body:
                'Defines the official name of the group and outlines its core mission and objectives.',
          ),
          ConstitutionSection(
            id: '2',
            title: 'Membership',
            body:
                'Eligibility criteria, joining procedures, rights & obligations, and termination clauses.',
          ),
          ConstitutionSection(
            id: '3',
            title: 'Meetings',
            body:
                'Scheduling, quorum requirements, decision-making process, and attendance expectations.',
          ),
          // Split Savings & Loans into separate structured sections
          ConstitutionSection(
            id: '4',
            title: 'Savings',
            kind: SectionKind.savings,
            body:
                'Rules for contributions, frequency, fixed vs variable, penalties for missed savings.',
            settings: {
              'frequency': 'weekly',
              'minContribution': 0.0,
              'fixedAmount': false,
              'fixedAmountValue': 0.0,
              'penaltyPerMiss': 0.0,
            },
          ),
          ConstitutionSection(
            id: '5',
            title: 'Loans',
            kind: SectionKind.loans,
            body:
                'Loan issuance, interest type & rate, limits, penalties and repayment schedule.',
            settings: {
              'interestType': 'flat',
              'interestRate': 0.0,
              'maxMultipleSavings': 3.0,
              'penaltyRate': 0.0,
              'maxDurationWeeks': 12,
            },
          ),
          ConstitutionSection(
            id: '6',
            title: 'Social Fund',
            kind: SectionKind.socialFund,
            body:
                'Social/welfare fund contribution rules and usage guidelines.',
            settings: {
              'contributionAmount': 0.0,
              'usageNotes': 'Emergency assistance & welfare needs',
              'approvalRule': 'Simple majority',
            },
          ),
          ConstitutionSection(
            id: '7',
            title: 'Fines',
            kind: SectionKind.fines,
            body: 'Fine types and default amounts defined by the group.',
            settings: {'fineTypes': <Map<String, dynamic>>[]},
          ),
        ]);
        await _repo.saveSections(_sections);
      } else {
        // Migration: if old combined section exists, split it
        bool migrated = false;
        bool hasFines = false;
        for (final s in loaded) {
          if (s.title == 'Savings & Loans') {
            migrated = true;
            _sections.addAll([
              ConstitutionSection(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Savings',
                kind: SectionKind.savings,
                body: s.body,
                settings: {
                  'frequency': 'weekly',
                  'minContribution': 0.0,
                  'fixedAmount': false,
                  'fixedAmountValue': 0.0,
                  'penaltyPerMiss': 0.0,
                },
              ),
              ConstitutionSection(
                id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
                title: 'Loans',
                kind: SectionKind.loans,
                body: s.body,
                settings: {
                  'interestType': 'flat',
                  'interestRate': 0.0,
                  'maxMultipleSavings': 3.0,
                  'penaltyRate': 0.0,
                  'maxDurationWeeks': 12,
                },
              ),
              ConstitutionSection(
                id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
                title: 'Social Fund',
                kind: SectionKind.socialFund,
                body:
                    'Social/welfare fund contribution rules and usage guidelines.',
                settings: {
                  'contributionAmount': 0.0,
                  'usageNotes': 'Emergency assistance & welfare needs',
                  'approvalRule': 'Simple majority',
                },
              ),
            ]);
          } else {
            _sections.add(s);
            if (s.kind == SectionKind.fines || s.title == 'Fines') {
              hasFines = true;
            }
          }
        }
        if (!hasFines) {
          _sections.add(
            ConstitutionSection(
              id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
              title: 'Fines',
              kind: SectionKind.fines,
              body: 'Fine types and default amounts defined by the group.',
              settings: {'fineTypes': <Map<String, dynamic>>[]},
            ),
          );
        }
        if (migrated || !hasFines) {
          await _repo.saveSections(_sections);
        } else if (_sections.isEmpty) {
          _sections.addAll(loaded);
        }
      }
    } catch (e) {
      _error = 'Failed to load constitution';
    }
    _loading = false;
    notifyListeners();
  }

  ConstitutionSection? getSectionById(String id) => _sections.firstWhere(
    (s) => s.id == id,
    orElse: () => ConstitutionSection(id: id, title: 'Not Found', body: ''),
  ); // fallback

  Future<void> refresh() async {
    await _init();
  }

  void updateSection(
    String id, {
    String? title,
    String? body,
    Map<String, dynamic>? settings,
  }) {
    if (_locked) return; // prevent edits
    final idx = _sections.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final current = _sections[idx];
    _sections[idx] = current.copyWith(
      title: title,
      body: body,
      settings: settings != null ? Map<String, dynamic>.from(settings) : null,
    );
    _repo.saveSections(_sections);
    notifyListeners();
  }

  void addSection(
    String title,
    String body, {
    SectionKind kind = SectionKind.generic,
    Map<String, dynamic>? settings,
  }) {
    if (_locked) return;
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _sections.add(
      ConstitutionSection(
        id: newId,
        title: title,
        body: body,
        kind: kind,
        settings: settings,
      ),
    );
    _repo.saveSections(_sections);
    notifyListeners();
  }

  void removeSection(String id) {
    if (_locked) return;
    _sections.removeWhere((s) => s.id == id);
    _repo.saveSections(_sections);
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (_locked) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, item);
    _repo.saveSections(_sections);
    notifyListeners();
  }

  Future<void> lockConstitution() async {
    if (_locked) return;
    await _repo.lock();
    _locked = true;
    notifyListeners();
  }

  // Sync local constitution sections to server via API
  Future<void> syncSectionsToServer(int cycleId) async {
    // Build request body from current sections
    final body = _buildApiBodyFromSections();
    final current = await _api.getCurrent(cycleId);
    if (current == null) {
      // create with version 1
      await _api.create(cycleId, {...body, 'version': 1, 'is_active': true});
    } else {
      await _api.update(cycleId, current.id, {
        ...body,
        'version': current.version + 1,
        'is_active': true,
      });
    }
  }

  Map<String, dynamic> _buildApiBodyFromSections() {
    // defaults
    double savingsAmount = 0.0;
    double interestRate = 0.0;
    String interestType = 'flat';
    double welfareAmount = 0.0;
    int minGuarantors = 1; // API requires at least 1
    String meetingFrequency = 'weekly';
    double lateFine = 0.0;
    double absentFine = 0.0;
    double missedSavingsFine = 0.0;
    final List<Map<String, String>> additionalRulesList = [];

    for (final s in _sections) {
      switch (s.kind) {
        case SectionKind.savings:
          // Choose minContribution for savings amount; frequency as meeting frequency
          savingsAmount =
              (s.settings['minContribution'] as num?)?.toDouble() ??
              savingsAmount;
          meetingFrequency =
              (s.settings['frequency'] as String?) ?? meetingFrequency;
          break;
        case SectionKind.loans:
          interestType =
              (s.settings['interestType'] as String?) ?? interestType;
          interestRate =
              (s.settings['interestRate'] as num?)?.toDouble() ?? interestRate;
          break;
        case SectionKind.socialFund:
          welfareAmount =
              (s.settings['contributionAmount'] as num?)?.toDouble() ??
              welfareAmount;
          break;
        case SectionKind.fines:
          final list =
              (s.settings['fineTypes'] as List?)?.cast<Map>() ?? const [];
          double findAmount(String key) {
            final match = list.firstWhere(
              (m) => (m['name']?.toString().toLowerCase() ?? '').contains(key),
              orElse: () => const {},
            );
            return (match['amount'] as num?)?.toDouble() ?? 0.0;
          }
          lateFine = lateFine != 0.0 ? lateFine : findAmount('late');
          absentFine = absentFine != 0.0 ? absentFine : findAmount('absent');
          // heuristics for missed savings
          final missed = list.firstWhere((m) {
            final name = (m['name']?.toString().toLowerCase() ?? '');
            return name.contains('miss') && name.contains('saving');
          }, orElse: () => const {});
          missedSavingsFine =
              (missed['amount'] as num?)?.toDouble() ?? missedSavingsFine;
          break;
        case SectionKind.generic:
          // Collect additional rules as structured items
          final title = s.title.trim();
          final body = s.body.trim();
          if (title.isNotEmpty || body.isNotEmpty) {
            additionalRulesList.add({'title': title, 'body': body});
          }
          break;
      }
    }

    return {
      'savings_amount': savingsAmount,
      'interest_rate': interestRate,
      'interest_type': interestType,
      'welfare_amount': welfareAmount,
      'min_guarantors': minGuarantors,
      'meeting_frequency': meetingFrequency,
      'late_fine': lateFine,
      'absent_fine': absentFine,
      'missed_savings_fine': missedSavingsFine,
      // API expects a JSON string; send '[]' when empty
      'additional_rules': jsonEncode(additionalRulesList),
    };
  }
}
