import 'package:archery_tracker/l10n/app_localizations_en.dart';
import 'package:archery_tracker/l10n/app_localizations_ja.dart';
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
    expect(en.monthlyGoalSetTitle, 'Set Monthly Goal');
    expect(en.monthlyGoalSaveSuccess, 'Monthly goal updated');
    expect(en.appName, 'Archery Record Pro');
    expect(en.chinese, 'Chinese');
    expect(en.chineseDisplayName, 'Simplified Chinese');
    expect(en.feedbackAndPrivacy, 'Feedback & Privacy');
    expect(en.aboutAppNameLabel, 'App Name');
    expect(en.aboutFeedbackLabel, 'Feedback');
    expect(en.aboutPrivacyPolicyLabel, 'Privacy Policy');
    expect(en.emailCopied, 'Email address copied');
    expect(en.privacyPolicyCopied, 'Privacy policy link copied');
  });

  test('new localization keys return expected Chinese copy', () {
    final zh = AppLocalizationsZh();

    expect(zh.scoringExitTitle, '退出计分？');
    expect(zh.scoringExitMessage, '当前记录将丢失。是否保存后退出？');
    expect(zh.sessionSetupEquipment, '器材设置');
    expect(zh.sessionSetupSelectLabel('距离'), '选择距离');
    expect(zh.myBowName(zh.bowCompound), '我的复合弓');
    expect(zh.aiCoachBasedOnCurrentSession, '基于本次训练的专业建议');
    expect(zh.monthlyGoalSetTitle, '设置月度目标');
    expect(zh.monthlyGoalSaveSuccess, '月度目标已更新');
    expect(zh.chineseDisplayName, '中文（简体）');
    expect(zh.feedbackAndPrivacy, '反馈与隐私');
    expect(zh.aboutAppNameLabel, 'App 名称');
    expect(zh.aboutFeedbackLabel, '反馈联系方式');
    expect(zh.aboutPrivacyPolicyLabel, '隐私协议');
    expect(zh.emailCopied, '邮箱地址已复制');
    expect(zh.privacyPolicyCopied, '隐私协议地址已复制');
  });

  test('new localization keys return expected Japanese copy', () {
    final ja = AppLocalizationsJa();

    expect(ja.appName, 'アーチェリーレコード Pro');
    expect(ja.scoringExitTitle, '採点を終了しますか？');
    expect(ja.monthlyGoalSetTitle, '月間目標を設定');
    expect(ja.chineseDisplayName, '簡体字中国語');
    expect(ja.englishDisplayName, '英語');
    expect(ja.japanese, '日本語');
    expect(ja.feedbackAndPrivacy, 'フィードバックとプライバシー');
    expect(ja.aboutAppNameLabel, 'アプリ名');
    expect(ja.emailCopied, 'メールアドレスをコピーしました');
  });
}
