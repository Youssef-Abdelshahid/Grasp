class AssignmentRubricItemModel {
  const AssignmentRubricItemModel({
    required this.criterion,
    required this.description,
    required this.marks,
  });

  final String criterion;
  final String description;
  final int marks;

  factory AssignmentRubricItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentRubricItemModel(
      criterion: json['criterion'] as String? ?? '',
      description: json['description'] as String? ?? '',
      marks: (json['marks'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'criterion': criterion, 'description': description, 'marks': marks};
  }
}
