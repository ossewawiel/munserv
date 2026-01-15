import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/models/issue_type.dart';
import 'package:munserv_mobile/shared/theme/issue_type_icons.dart';

void main() {
  group('IssueTypeVisuals', () {
    test('forType returns visuals for all issue types', () {
      for (final type in IssueType.values) {
        final visuals = IssueTypeVisuals.forType(type);
        expect(visuals, isNotNull);
        expect(visuals.icon, isA<IconData>());
        expect(visuals.filledIcon, isA<IconData>());
        expect(visuals.color, isA<Color>());
        expect(visuals.lightColor, isA<Color>());
        expect(visuals.semanticLabel, isNotEmpty);
      }
    });

    test('pothole has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.pothole);
      expect(visuals.icon, equals(Icons.warning_amber_rounded));
      expect(visuals.filledIcon, equals(Icons.warning_rounded));
      expect(visuals.color, equals(const Color(0xFFE65100)));
      expect(visuals.lightColor, equals(const Color(0xFFFFF3E0)));
      expect(visuals.semanticLabel, equals('Pothole hazard'));
    });

    test('waterLeak has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.waterLeak);
      expect(visuals.icon, equals(Icons.water_drop_outlined));
      expect(visuals.filledIcon, equals(Icons.water_drop));
      expect(visuals.color, equals(const Color(0xFF0288D1)));
      expect(visuals.lightColor, equals(const Color(0xFFE1F5FE)));
      expect(visuals.semanticLabel, equals('Water leak'));
    });

    test('sewageLeak has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.sewageLeak);
      expect(visuals.icon, equals(Icons.waves_outlined));
      expect(visuals.filledIcon, equals(Icons.waves));
      expect(visuals.color, equals(const Color(0xFF5D4037)));
      expect(visuals.lightColor, equals(const Color(0xFFEFEBE9)));
      expect(visuals.semanticLabel, equals('Sewage leak'));
    });

    test('trafficLight has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.trafficLight);
      expect(visuals.icon, equals(Icons.traffic_outlined));
      expect(visuals.filledIcon, equals(Icons.traffic));
      expect(visuals.color, equals(const Color(0xFFC62828)));
      expect(visuals.lightColor, equals(const Color(0xFFFFEBEE)));
      expect(visuals.semanticLabel, equals('Traffic light issue'));
    });

    test('streetLight has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.streetLight);
      expect(visuals.icon, equals(Icons.lightbulb_outline));
      expect(visuals.filledIcon, equals(Icons.lightbulb));
      expect(visuals.color, equals(const Color(0xFFF9A825)));
      expect(visuals.lightColor, equals(const Color(0xFFFFFDE7)));
      expect(visuals.semanticLabel, equals('Street light issue'));
    });

    test('illegalDumping has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.illegalDumping);
      expect(visuals.icon, equals(Icons.delete_outline));
      expect(visuals.filledIcon, equals(Icons.delete));
      expect(visuals.color, equals(const Color(0xFF2E7D32)));
      expect(visuals.lightColor, equals(const Color(0xFFE8F5E9)));
      expect(visuals.semanticLabel, equals('Illegal dumping'));
    });

    test('roadDamage has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.roadDamage);
      expect(visuals.icon, equals(Icons.trending_down_outlined));
      expect(visuals.filledIcon, equals(Icons.trending_down));
      expect(visuals.color, equals(const Color(0xFF37474F)));
      expect(visuals.lightColor, equals(const Color(0xFFECEFF1)));
      expect(visuals.semanticLabel, equals('Road damage'));
    });

    test('other has correct configuration', () {
      final visuals = IssueTypeVisuals.forType(IssueType.other);
      expect(visuals.icon, equals(Icons.help_outline));
      expect(visuals.filledIcon, equals(Icons.help));
      expect(visuals.color, equals(const Color(0xFF616161)));
      expect(visuals.lightColor, equals(const Color(0xFFF5F5F5)));
      expect(visuals.semanticLabel, equals('Other issue'));
    });

    test('each type has distinct color', () {
      final colors = <Color>{};
      for (final type in IssueType.values) {
        final visuals = IssueTypeVisuals.forType(type);
        expect(
          colors.contains(visuals.color),
          isFalse,
          reason: '${type.name} color should be unique',
        );
        colors.add(visuals.color);
      }
    });

    test('light colors are lighter than main colors', () {
      for (final type in IssueType.values) {
        final visuals = IssueTypeVisuals.forType(type);
        // Light color should have higher luminance (be lighter)
        final mainLuminance = visuals.color.computeLuminance();
        final lightLuminance = visuals.lightColor.computeLuminance();
        expect(
          lightLuminance,
          greaterThan(mainLuminance),
          reason: '${type.name} lightColor should be lighter than color',
        );
      }
    });
  });
}
