import '../../models/models.dart';
import 'in_memory_auth_repository.dart';

/// Sample data so the app is explorable on the mock backend. Sign in as
/// [ownerEmail] (any non-empty password) to see the seeded lists as owner.
abstract final class SeedData {
  static const String ownerEmail = 'demo@giftlist.dev';
  static const String allowedGuestEmail = 'guest@giftlist.dev';

  static String get ownerId =>
      InMemoryAuthRepository.userIdForEmail(ownerEmail);

  static Profile ownerProfile() => Profile(
    id: ownerId,
    displayName: 'Ana Demo',
    createdAt: DateTime(2026),
    defaultPixKey: ownerEmail,
    pixKeyType: PixKeyType.email,
    merchantCity: 'SAO PAULO',
  );

  static List<GiftList> lists() => [
    GiftList(
      id: 'list-casa-nova',
      ownerId: ownerId,
      slug: 'casa-nova-ana',
      title: 'Casa Nova da Ana',
      occasion: Occasion.newHome,
      description: 'Ajude a mobiliar meu novo apê!',
      pixKey: ownerEmail,
      pixKeyType: PixKeyType.email,
      merchantName: 'ANA DEMO',
      visibility: ListVisibility.public,
      contributorAuth: ContributorAuth.anonymous,
      isPublished: true,
      createdAt: DateTime(2026, 2),
    ),
    GiftList(
      id: 'list-cha-bebe',
      ownerId: ownerId,
      slug: 'cha-bebe-bia',
      title: 'Chá de Bebê da Bia',
      occasion: Occasion.baby,
      pixKey: ownerEmail,
      pixKeyType: PixKeyType.email,
      merchantName: 'ANA DEMO',
      visibility: ListVisibility.public,
      contributorAuth: ContributorAuth.loginRequired,
      isPublished: true,
      createdAt: DateTime(2026, 3),
    ),
    GiftList(
      id: 'list-casamento',
      ownerId: ownerId,
      slug: 'casamento-secreto',
      title: 'Casamento (privado)',
      occasion: Occasion.wedding,
      pixKey: ownerEmail,
      pixKeyType: PixKeyType.email,
      merchantName: 'ANA DEMO',
      visibility: ListVisibility.private,
      contributorAuth: ContributorAuth.loginRequired,
      isPublished: true,
      createdAt: DateTime(2026, 4),
    ),
  ];

  static Map<String, List<AllowlistEntry>> allowlist() => {
    'list-casamento': const [
      AllowlistEntry(id: 'al-1', email: allowedGuestEmail),
    ],
  };

  static List<GiftItem> items() => [
    GiftItem(
      id: 'item-sofa',
      listId: 'list-casa-nova',
      title: 'Sofá 3 lugares',
      description: 'Cinza, retrátil',
      targetAmountCents: 250000,
      allowPartial: false,
      position: 0,
      createdAt: DateTime(2026, 2),
    ),
    GiftItem(
      id: 'item-geladeira',
      listId: 'list-casa-nova',
      title: 'Geladeira',
      targetAmountCents: 400000,
      allowPartial: true,
      position: 1,
      createdAt: DateTime(2026, 2),
    ),
    GiftItem(
      id: 'item-panelas',
      listId: 'list-casa-nova',
      title: 'Jogo de panelas',
      targetAmountCents: 60000,
      allowPartial: false,
      position: 2,
      createdAt: DateTime(2026, 2),
    ),
    GiftItem(
      id: 'item-carrinho',
      listId: 'list-cha-bebe',
      title: 'Carrinho de bebê',
      targetAmountCents: 180000,
      allowPartial: true,
      position: 0,
      createdAt: DateTime(2026, 3),
    ),
  ];

  /// One confirmed and one live reservation on the public list, so progress
  /// badges have something to show.
  static List<Contribution> contributions() {
    final now = DateTime.now();
    return [
      Contribution(
        id: 'contrib-1',
        itemId: 'item-panelas',
        listId: 'list-casa-nova',
        giverName: 'Tio João',
        giverMessage: 'Parabéns pela casa nova!',
        amountCents: 60000,
        status: ContributionStatus.confirmed,
        pixTxid: 'SEEDTXN001',
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.subtract(const Duration(days: 2, hours: -1)),
        confirmedAt: now.subtract(const Duration(days: 1)),
      ),
      Contribution(
        id: 'contrib-2',
        itemId: 'item-geladeira',
        listId: 'list-casa-nova',
        giverName: 'Prima Carol',
        amountCents: 100000,
        status: ContributionStatus.awaitingConfirmation,
        pixTxid: 'SEEDTXN002',
        createdAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.add(const Duration(minutes: 35)),
      ),
    ];
  }
}
