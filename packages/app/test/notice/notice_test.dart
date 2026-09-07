import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/notice/notice.dart';

void main() {
  group('the sealed notice type', () {
    test('every variant carries its sentence as a payload', () {
      // assert
      expect(
        const LoadNotice(
          'your last save could not be read; an older one '
          'was restored',
        ).sentence,
        'your last save could not be read; an older one was restored',
      );
      expect(
        const SaveWriteFailedNotice(
          'the game could not be saved; your last '
          'save still stands',
        ).sentence,
        'the game could not be saved; your last save still stands',
      );
      expect(
        const ResumeRefusedNotice(
          'the camp at the crypt has been taken back '
          'by the residue',
        ).sentence,
        'the camp at the crypt has been taken back by the residue',
      );
      expect(
        const SentenceNotice('you cannot afford a bed').sentence,
        'you cannot afford a bed',
      );
    });

    test('two notices of one kind and sentence are equal', () {
      // assert
      expect(
        const SentenceNotice('you cannot afford a bed'),
        const SentenceNotice('you cannot afford a bed'),
      );
      expect(
        const SentenceNotice('you cannot afford a bed'),
        isNot(const SentenceNotice('you are not carrying that')),
      );
      expect(
        const LoadNotice('a sentence'),
        isNot(const SentenceNotice('a sentence')),
      );
    });
  });
}
