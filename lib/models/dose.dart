// lib/models/dose.dart

class Dose {
  final String title;
  final String subtitle;
  final String answer;

  Dose({
    required this.title,
    required this.subtitle,
    required this.answer,
  });

  factory Dose.fromJson(Map<String, dynamic> json) {
    return Dose(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'answer': answer,
    };
  }

  @override
  String toString() {
    return 'Dose(title: $title, subtitle: $subtitle, answer: ${answer.substring(0, answer.length > 50 ? 50 : answer.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dose &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.answer == answer;
  }

  @override
  int get hashCode => title.hashCode ^ subtitle.hashCode ^ answer.hashCode;
}