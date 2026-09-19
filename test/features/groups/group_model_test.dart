import 'package:flutter_test/flutter_test.dart';
import 'package:pagella_sanremo/features/groups/models/group.dart';

void main() {
  group('Group.fromMap', () {
    test('legge tutti i campi', () {
      final group = Group.fromMap({
        'id': 'g1',
        'name': 'Amici',
        'emoji': '🎤',
        'code': 'ABC234',
        'owner_id': 'u1',
        'created_at': '2026-02-24T21:00:00Z',
        'member_count': 4,
      });

      expect(group.id, 'g1');
      expect(group.name, 'Amici');
      expect(group.emoji, '🎤');
      expect(group.code, 'ABC234');
      expect(group.ownerId, 'u1');
      expect(group.createdAt, DateTime.utc(2026, 2, 24, 21));
      expect(group.memberCount, 4);
    });

    test('usa i default per emoji e conteggio membri assenti', () {
      final group = Group.fromMap({
        'id': 'g1',
        'name': 'Amici',
        'code': 'ABC234',
        'owner_id': 'u1',
        'created_at': '2026-02-24T21:00:00Z',
      });

      expect(group.emoji, '👥');
      expect(group.memberCount, 0);
    });
  });

  group('MemberArtistVote.average', () {
    test('fa la media delle sole categorie votate', () {
      const vote = MemberArtistVote(username: 'anna', canto: 8, look: 6);

      expect(vote.average, 7);
    });

    test('è null se non c\'è nessun voto', () {
      const vote = MemberArtistVote(username: 'anna');

      expect(vote.average, isNull);
    });
  });
}
