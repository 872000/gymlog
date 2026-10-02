/// An exercise from the bundled library or added by the user.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final bool isCustom;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'equipment': equipment,
        'is_custom': isCustom ? 1 : 0,
      };

  factory Exercise.fromMap(Map<String, Object?> map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        muscleGroup: map['muscle_group'] as String,
        equipment: map['equipment'] as String,
        isCustom: (map['is_custom'] as int? ?? 0) == 1,
      );
}
