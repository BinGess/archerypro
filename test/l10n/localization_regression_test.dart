import 'package:archery_tracker/l10n/app_localizations_en.dart';
import 'package:archery_tracker/l10n/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new localization keys return expected English copy', () {
    final en = AppLocalizationsEn();

    expect(en.scoringExitTitle, 'Exit Scoring?');
    expect(en.scoringExitMessage,
        'Current records will be lost. Save before exit?');
    expect(en.sessionSetupEquipment, 'Equipment');
    expect(en.sessionSetupSelectLabel('Distance'), 'Select Distance');
    expect(en.myBowName(en.bowCompound), 'My Compound');
    expect(en.aiCoachBasedOnCurrentSession,
        'Professional advice based on this session');
  });

  test('new localization keys return expected Chinese copy', () {
    final zh = AppLocalizationsZh();

    expect(zh.scoringExitTitle, '退出计分？');
    expect(zh.scoringExitMessage, '当前记录将丢失。是否保存后退出？');
    expect(zh.sessionSetupEquipment, '器材设置');
    expect(zh.sessionSetupSelectLabel('距离'), '选择距离');
    expect(zh.myBowName(zh.bowCompound), '我的复合弓');
    expect(zh.aiCoachBasedOnCurrentSession, '基于本次训练的专业建议');
  });
}
