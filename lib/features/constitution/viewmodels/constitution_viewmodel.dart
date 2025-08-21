import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../data/api/constitution_api_repository.dart';
import '../data/constitution_repository.dart';

enum SectionKind { generic, meetings, savings, loans, socialFund, fines }

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
  int? _hydratedCycleId; // cycle id we've hydrated API defaults for

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
            kind: SectionKind.meetings,
            body: 'Meeting schedule and cadence for the cycle.',
            settings: {
              'frequency': 'weekly',
              'meetingDay': 'monday',
              'meetingCount': 12,
            },
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
          } else if (s.title == 'Meetings' && s.kind == SectionKind.generic) {
            // Migrate old generic Meetings to structured Meetings section
            migrated = true;
            _sections.add(
              ConstitutionSection(
                id: s.id,
                title: 'Meetings',
                kind: SectionKind.meetings,
                body: 'Meeting schedule and cadence for the cycle.',
                settings: {
                  'frequency': 'weekly',
                  'meetingDay': 'monday',
                  'meetingCount': 12,
                },
              ),
            );
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

  // One-time hydration of fields from API defaults for a given cycle
  Future<void> hydrateFromApiIfNeeded(int cycleId) async {
    if (_hydratedCycleId == cycleId) return;
    try {
      _loading = true;
      notifyListeners();
      final dto = await _api.getCurrent(cycleId);
      if (dto != null) {
        _applyApiDefaults(dto);
        await _repo.saveSections(_sections);
      }
      _hydratedCycleId = cycleId;
    } catch (_) {
      // non-fatal; keep local state
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _applyApiDefaults(ConstitutionDto dto) {
    // Ensure key sections exist
    int idxMeetings = _sections.indexWhere(
      (s) => s.kind == SectionKind.meetings,
    );
    if (idxMeetings == -1) {
      _sections.add(
        ConstitutionSection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Meetings',
          kind: SectionKind.meetings,
          body: 'Meeting schedule and cadence for the cycle.',
          settings: {
            'frequency': 'weekly',
            'meetingDay': 'monday',
            'meetingCount': 12,
          },
        ),
      );
      idxMeetings = _sections.length - 1;
    }
    int idxSavings = _sections.indexWhere((s) => s.kind == SectionKind.savings);
    if (idxSavings == -1) {
      _sections.add(
        ConstitutionSection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      );
      idxSavings = _sections.length - 1;
    }

    int idxLoans = _sections.indexWhere((s) => s.kind == SectionKind.loans);
    if (idxLoans == -1) {
      _sections.add(
        ConstitutionSection(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
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
      );
      idxLoans = _sections.length - 1;
    }

    int idxSocial = _sections.indexWhere(
      (s) => s.kind == SectionKind.socialFund,
    );
    if (idxSocial == -1) {
      _sections.add(
        ConstitutionSection(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          title: 'Social Fund',
          kind: SectionKind.socialFund,
          body: 'Social/welfare fund contribution rules and usage guidelines.',
          settings: {
            'contributionAmount': 0.0,
            'usageNotes': 'Emergency assistance & welfare needs',
            'approvalRule': 'Simple majority',
          },
        ),
      );
      idxSocial = _sections.length - 1;
    }

    int idxFines = _sections.indexWhere((s) => s.kind == SectionKind.fines);
    if (idxFines == -1) {
      _sections.add(
        ConstitutionSection(
          id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
          title: 'Fines',
          kind: SectionKind.fines,
          body: 'Fine types and default amounts defined by the group.',
          settings: {'fineTypes': <Map<String, dynamic>>[]},
        ),
      );
      idxFines = _sections.length - 1;
    }

    // Helpers to only set when empty/zero
    T _preferExisting<T>(dynamic current, T incoming) {
      if (current == null) return incoming;
      if (current is num) {
        return (current == 0 ? incoming : current) as T;
      }
      if (current is String) {
        return (current.isEmpty ? incoming : current) as T;
      }
      return current as T;
    }

    // Apply Meetings defaults
    final sMeetings = _sections[idxMeetings].settings;
    sMeetings['frequency'] = _preferExisting<String>(
      sMeetings['frequency'],
      dto.meetingFrequency.isNotEmpty ? dto.meetingFrequency : 'weekly',
    );
    sMeetings['meetingDay'] = _preferExisting<String>(
      sMeetings['meetingDay'],
      dto.meetingDay.isNotEmpty ? dto.meetingDay : 'monday',
    );
    sMeetings['meetingCount'] = _preferExisting<int>(
      sMeetings['meetingCount'],
      dto.meetingCount > 0 ? dto.meetingCount : 12,
    );

    // Apply Savings defaults
    final sSavings = _sections[idxSavings].settings;
    sSavings['minContribution'] = _preferExisting<double>(
      sSavings['minContribution'],
      dto.savingsAmount,
    );
    sSavings['penaltyPerMiss'] = _preferExisting<double>(
      sSavings['penaltyPerMiss'],
      dto.missedSavingsFine,
    );

    // Apply Loans defaults
    final sLoans = _sections[idxLoans].settings;
    sLoans['interestType'] = _preferExisting<String>(
      sLoans['interestType'],
      dto.interestType.isNotEmpty ? dto.interestType : 'flat',
    );
    sLoans['interestRate'] = _preferExisting<double>(
      sLoans['interestRate'],
      dto.interestRate,
    );

    // Apply Social Fund defaults
    final sSocial = _sections[idxSocial].settings;
    sSocial['contributionAmount'] = _preferExisting<double>(
      sSocial['contributionAmount'],
      dto.welfareAmount,
    );

    // Apply Fines defaults: populate standard fine types if empty
    final sFines = _sections[idxFines].settings;
    final currentFineTypes = (sFines['fineTypes'] as List?)?.cast<Map>() ?? [];
    if (currentFineTypes.isEmpty) {
      sFines['fineTypes'] = [
        {'name': 'Late coming', 'amount': dto.lateFine},
        {'name': 'Absent', 'amount': dto.absentFine},
        {'name': 'Missed savings', 'amount': dto.missedSavingsFine},
      ];
    }
    // Also set explicit fine fields for editor bindings
    sFines['lateFine'] =
        (sFines['lateFine'] as num?)?.toDouble() ?? dto.lateFine;
    sFines['absentFine'] =
        (sFines['absentFine'] as num?)?.toDouble() ?? dto.absentFine;
    sFines['missedSavingsFine'] =
        (sFines['missedSavingsFine'] as num?)?.toDouble() ??
        dto.missedSavingsFine;

    // Apply group-level settings that don't fit sections neatly
    // Min guarantors can be part of Loans rules
    sLoans['minGuarantors'] = _preferExisting<int>(
      sLoans['minGuarantors'],
      dto.minGuarantors > 0 ? dto.minGuarantors : 1,
    );

    // Additional rules (JSON string). We keep generic sections; here we may parse and ignore if UI not displaying.
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
    String meetingDay = 'monday';
    int meetingCount = 12;
    double lateFine = 0.0;
    double absentFine = 0.0;
    double missedSavingsFine = 0.0;
    final List<Map<String, String>> additionalRulesList = [];

    for (final s in _sections) {
      switch (s.kind) {
        case SectionKind.savings:
          // Choose minContribution for savings amount
          savingsAmount =
              (s.settings['minContribution'] as num?)?.toDouble() ??
              savingsAmount;
          break;
        case SectionKind.meetings:
          meetingFrequency =
              (s.settings['frequency'] as String?) ?? meetingFrequency;
          meetingDay = (s.settings['meetingDay'] as String?) ?? meetingDay;
          meetingCount = (s.settings['meetingCount'] as int?) ?? meetingCount;
          break;
        case SectionKind.loans:
          interestType =
              (s.settings['interestType'] as String?) ?? interestType;
          interestRate =
              (s.settings['interestRate'] as num?)?.toDouble() ?? interestRate;
          minGuarantors =
              (s.settings['minGuarantors'] as int?) ?? minGuarantors;
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
          // Prefer explicit fields if present, else infer from fineTypes list
          lateFine =
              (s.settings['lateFine'] as num?)?.toDouble() ??
              (lateFine != 0.0 ? lateFine : findAmount('late'));
          absentFine =
              (s.settings['absentFine'] as num?)?.toDouble() ??
              (absentFine != 0.0 ? absentFine : findAmount('absent'));
          // heuristics for missed savings
          final missed = list.firstWhere((m) {
            final name = (m['name']?.toString().toLowerCase() ?? '');
            return name.contains('miss') && name.contains('saving');
          }, orElse: () => const {});
          missedSavingsFine =
              (s.settings['missedSavingsFine'] as num?)?.toDouble() ??
              (missed['amount'] as num?)?.toDouble() ??
              missedSavingsFine;
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
      'meeting_day': meetingDay,
      'meeting_count': meetingCount,
      'late_fine': lateFine,
      'absent_fine': absentFine,
      'missed_savings_fine': missedSavingsFine,
      // API expects a JSON string; send '[]' when empty
      'additional_rules': jsonEncode(additionalRulesList),
    };
  }
}
