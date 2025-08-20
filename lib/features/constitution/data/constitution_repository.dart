import 'package:hive/hive.dart';
import '../viewmodels/constitution_viewmodel.dart';

/// Repository responsible for persisting the constitution & lock state locally.
/// For now we use a simple Hive box storing a list of section maps and a lock flag.
class ConstitutionRepository {
  static const String _boxName = 'constitution_box';
  static const String _sectionsKey = 'sections';
  static const String _lockedKey = 'locked';

  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Future<List<ConstitutionSection>> loadSections() async {
    await init();
    final raw = _box!.get(_sectionsKey) as List?;
    if (raw == null) return [];
    return raw.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ConstitutionSection(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        kind: SectionKind.values.firstWhere(
          (k) => k.toString() == (map['kind'] as String? ?? ''),
          orElse: () => SectionKind.generic,
        ),
        settings: Map<String, dynamic>.from(map['settings'] as Map? ?? {}),
      );
    }).toList();
  }

  Future<void> saveSections(List<ConstitutionSection> sections) async {
    await init();
    final data =
        sections
            .map(
              (s) => {
                'id': s.id,
                'title': s.title,
                'body': s.body,
                'kind': s.kind.toString(),
                'settings': s.settings,
              },
            )
            .toList();
    await _box!.put(_sectionsKey, data);
  }

  Future<bool> isLocked() async {
    await init();
    return _box!.get(_lockedKey, defaultValue: false) as bool;
  }

  Future<void> lock() async {
    await init();
    await _box!.put(_lockedKey, true);
  }
}
