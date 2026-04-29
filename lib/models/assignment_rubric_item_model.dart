class AssignmentRubricItemModel {
  const AssignmentRubricItemModel({
    required this.criterion,
    required this.description,
    required this.marks,
    this.sourceReference = const {},
  });

  final String criterion;
  final String description;
  final int marks;
  final Map<String, dynamic> sourceReference;

  factory AssignmentRubricItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentRubricItemModel(
      criterion: json['criterion'] as String? ?? '',
      description: json['description'] as String? ?? '',
      marks: (json['marks'] as num?)?.toInt() ?? 0,
      sourceReference: Map<String, dynamic>.from(
        json['source_ref'] as Map? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criterion': criterion,
      'description': description,
      'marks': marks,
      if (sourceReference.isNotEmpty) 'source_ref': sourceReference,
    };
  }
}
