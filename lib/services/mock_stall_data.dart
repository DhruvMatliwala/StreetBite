import 'package:streetbite/models/menu_item.dart';
import 'package:streetbite/models/review.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/utils/geohash_util.dart';

/// Curated street food stalls and reviews used in Demo / Offline fallback mode.
abstract final class MockStallData {
  static const String demoVendorId = 'demo-vendor-001';

  static List<Stall> buildInitialStalls() {
    final now = DateTime.now();

    Stall makeStall({
      required String id,
      required String vendorId,
      required String name,
      required String description,
      required String address,
      required double latitude,
      required double longitude,
      required bool isOpen,
      required String operatingHours,
      required String bannerImageUrl,
      required List<MenuItem> menuItems,
      required List<String> crowdTags,
      required double tasteRating,
      required double hygieneRating,
      required int reviewCount,
    }) {
      return Stall(
        id: id,
        vendorId: vendorId,
        name: name,
        description: description,
        address: address,
        latitude: latitude,
        longitude: longitude,
        geohash: GeohashUtil.encode(latitude, longitude),
        isOpen: isOpen,
        operatingHours: operatingHours,
        bannerImageUrl: bannerImageUrl,
        galleryUrls: <String>[bannerImageUrl],
        menuItems: menuItems,
        searchableItems: Stall.buildSearchableTokens(
          name: name,
          menuItems: menuItems,
          crowdTags: crowdTags,
        ),
        crowdTags: crowdTags,
        tasteRating: tasteRating,
        hygieneRating: hygieneRating,
        reviewCount: reviewCount,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(minutes: 25)),
      );
    }

    return <Stall>[
      makeStall(
        id: 'stall-momos-01',
        vendorId: demoVendorId,
        name: 'Pahadi Steam & Tandoor Momos',
        description:
            'Hand-folded Himalayan momos steamed fresh every batch and served with fiery red garlic chutney.',
        address: 'Opp. VR Mall Gate 2, Dumas Road, Surat',
        latitude: 21.1498,
        longitude: 72.7718,
        isOpen: true,
        operatingHours: '4:30 PM - 11:30 PM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm1',
            name: 'Veg Steamed Momos (8 pcs)',
            price: 80,
            isVeg: true,
            category: 'Momos',
            description: 'Cabbage, carrot, ginger & scallions with spicy dip.',
          ),
          MenuItem(
            id: 'm2',
            name: 'Paneer Kurkure Momos',
            price: 120,
            isVeg: true,
            category: 'Momos',
            description: 'Crispy cornflake-crusted momos tossed in chaat masala.',
          ),
          MenuItem(
            id: 'm3',
            name: 'Tandoori Chicken Momos',
            price: 140,
            isVeg: false,
            category: 'Momos',
            description: 'Charcoal-smoked chicken momos with mint mayo.',
          ),
        ],
        crowdTags: const <String>['Student hangout', 'Spicy favorite', 'Evening rush'],
        tasteRating: 4.8,
        hygieneRating: 4.6,
        reviewCount: 64,
      ),
      makeStall(
        id: 'stall-locho-02',
        vendorId: demoVendorId,
        name: 'Gopi Surti Locho & Khamani Cart',
        description:
            'Authentic steamed Surti locho swimming in Amul butter, topped with sev, onions & green chutney.',
        address: 'Near Athwa Gate Circle, Surat',
        latitude: 21.1815,
        longitude: 72.8150,
        isOpen: true,
        operatingHours: '7:00 AM - 1:30 PM, 5:00 PM - 9:30 PM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm4',
            name: 'Butter Cheese Locho',
            price: 70,
            isVeg: true,
            category: 'Surti Specials',
            description: 'Warm gram-flour locho loaded with butter & cheddar.',
          ),
          MenuItem(
            id: 'm5',
            name: 'Amiri Sev Khamani',
            price: 60,
            isVeg: true,
            category: 'Surti Specials',
            description: 'Sweet-tangy crushed khaman topped with pomegranate & sev.',
          ),
          MenuItem(
            id: 'm6',
            name: 'Masala Idada',
            price: 45,
            isVeg: true,
            category: 'Surti Specials',
          ),
        ],
        crowdTags: const <String>['Pure veg', 'Pocket friendly', 'Hygiene star'],
        tasteRating: 4.9,
        hygieneRating: 4.7,
        reviewCount: 112,
      ),
      makeStall(
        id: 'stall-chaat-03',
        vendorId: 'vendor-003',
        name: 'Banaras Chaat Junction',
        description:
            'Crisp palak patta chaat, chilled dahi puri, and sizzling aloo tikki cooked in pure ghee.',
        address: 'City Light Main Road, Near Science Centre',
        latitude: 21.1674,
        longitude: 72.7932,
        isOpen: true,
        operatingHours: '5:00 PM - 11:00 PM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1606491956689-2ea866880c84?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm7',
            name: 'Dahi Sev Puri Chaat',
            price: 60,
            isVeg: true,
            category: 'Chaat',
          ),
          MenuItem(
            id: 'm8',
            name: 'Crispy Palak Patta Chaat',
            price: 85,
            isVeg: true,
            category: 'Chaat',
          ),
          MenuItem(
            id: 'm9',
            name: 'Desi Ghee Aloo Tikki',
            price: 70,
            isVeg: true,
            category: 'Chaat',
          ),
        ],
        crowdTags: const <String>['Pure veg', 'Family friendly', 'Hygiene star'],
        tasteRating: 4.7,
        hygieneRating: 4.8,
        reviewCount: 89,
      ),
      makeStall(
        id: 'stall-vadapav-04',
        vendorId: 'vendor-004',
        name: 'Bombay Express Butter Vada Pav',
        description:
            'Mumbai-style garlic-chutney vada pav served piping hot inside butter-toasted ladi pav.',
        address: 'Ghod Dod Road, Near Ram Chowk',
        latitude: 21.1748,
        longitude: 72.8075,
        isOpen: true,
        operatingHours: '10:30 AM - 10:30 PM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1666190092689-e3968aa0c32c?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm10',
            name: 'Classic Cheese Butter Vada Pav',
            price: 40,
            isVeg: true,
            category: 'Vada Pav',
          ),
          MenuItem(
            id: 'm11',
            name: 'Schezwan Grill Vada Pav',
            price: 50,
            isVeg: true,
            category: 'Vada Pav',
          ),
          MenuItem(
            id: 'm12',
            name: 'Cutting Masala Chai',
            price: 20,
            isVeg: true,
            category: 'Beverages',
          ),
        ],
        crowdTags: const <String>['Pocket friendly', 'Quick bite', 'Pure veg'],
        tasteRating: 4.6,
        hygieneRating: 4.4,
        reviewCount: 73,
      ),
      makeStall(
        id: 'stall-maggi-05',
        vendorId: 'vendor-005',
        name: 'Midnight Tawa Maggi & Chai Point',
        description:
            'Late-night comfort station for cheese butter maggi, bun maska, and ginger cardamom chai.',
        address: 'SVNIT Circle, Ichchhanath',
        latitude: 21.1663,
        longitude: 72.7834,
        isOpen: true,
        operatingHours: '7:00 PM - 3:00 AM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm13',
            name: 'Tadka Cheese Butter Maggi',
            price: 75,
            isVeg: true,
            category: 'Maggi',
          ),
          MenuItem(
            id: 'm14',
            name: 'Peri-Peri Vegetable Maggi',
            price: 65,
            isVeg: true,
            category: 'Maggi',
          ),
          MenuItem(
            id: 'm15',
            name: 'Egg Bhurji Maggi',
            price: 90,
            isVeg: false,
            category: 'Maggi',
          ),
        ],
        crowdTags: const <String>['Late-night spot', 'Student hangout', 'Pocket friendly'],
        tasteRating: 4.5,
        hygieneRating: 4.2,
        reviewCount: 54,
      ),
      makeStall(
        id: 'stall-pavbhaji-06',
        vendorId: 'vendor-006',
        name: 'Raju Bhai Tawa Pav Bhaji',
        description:
            'Slow-mashed spiced vegetable bhaji finished with smoky tawa butter and crisp garlic pav.',
        address: 'Adajan Patiya, New Rander Road',
        latitude: 21.2010,
        longitude: 72.8012,
        isOpen: false,
        operatingHours: '6:00 PM - 12:00 AM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm16',
            name: 'Special Amul Butter Pav Bhaji',
            price: 110,
            isVeg: true,
            category: 'Pav Bhaji',
          ),
          MenuItem(
            id: 'm17',
            name: 'Tawa Cheese Pulao',
            price: 120,
            isVeg: true,
            category: 'Pav Bhaji',
          ),
        ],
        crowdTags: const <String>['Late-night spot', 'Family friendly', 'Pure veg'],
        tasteRating: 4.7,
        hygieneRating: 4.5,
        reviewCount: 95,
      ),
      makeStall(
        id: 'stall-rolls-07',
        vendorId: 'vendor-007',
        name: 'Calcutta Kathi Roll Cart',
        description:
            'Flaky lachha parathas wrapped around smoky paneer tikka and spiced double-egg chicken fillings.',
        address: 'Vesu VIP Road, Near Canal Walk',
        latitude: 21.1390,
        longitude: 72.7795,
        isOpen: true,
        operatingHours: '5:30 PM - 1:00 AM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm18',
            name: 'Double Egg Chicken Kathi Roll',
            price: 130,
            isVeg: false,
            category: 'Rolls',
          ),
          MenuItem(
            id: 'm19',
            name: 'Paneer Tikka Masala Roll',
            price: 110,
            isVeg: true,
            category: 'Rolls',
          ),
        ],
        crowdTags: const <String>['Late-night spot', 'Spicy favorite'],
        tasteRating: 4.6,
        hygieneRating: 4.4,
        reviewCount: 47,
      ),
      makeStall(
        id: 'stall-kulfi-08',
        vendorId: 'vendor-008',
        name: 'Dumas Beach Matka Kulfi & Chaat',
        description:
            'Saffron-pistachio matka kulfi and crunchy beachside bhel just off the coastal promenade.',
        address: 'Dumas Sea Face Road, Surat',
        latitude: 21.0842,
        longitude: 72.7078,
        isOpen: true,
        operatingHours: '3:00 PM - 11:30 PM',
        bannerImageUrl:
            'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=1000&q=80',
        menuItems: const <MenuItem>[
          MenuItem(
            id: 'm20',
            name: 'Kesar Pista Matka Kulfi',
            price: 60,
            isVeg: true,
            category: 'Desserts',
          ),
          MenuItem(
            id: 'm21',
            name: 'Coastal Bhel Chaat',
            price: 50,
            isVeg: true,
            category: 'Chaat',
          ),
        ],
        crowdTags: const <String>['Family friendly', 'Pocket friendly'],
        tasteRating: 4.4,
        hygieneRating: 4.5,
        reviewCount: 38,
      ),
    ];
  }

  static Map<String, List<Review>> buildInitialReviews() {
    final now = DateTime.now();
    return <String, List<Review>>{
      'stall-momos-01': <Review>[
        Review(
          id: 'rev-1',
          stallId: 'stall-momos-01',
          authorUid: 'user-101',
          authorName: 'Aarav Patel',
          tasteRating: 5.0,
          hygieneRating: 4.5,
          comment:
              'Best kurkure momos on Dumas Road! Chutney packs serious heat and the cart stays spotless.',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        Review(
          id: 'rev-2',
          stallId: 'stall-momos-01',
          authorUid: 'user-102',
          authorName: 'Meera Shah',
          tasteRating: 4.6,
          hygieneRating: 4.7,
          comment: 'Freshly steamed in front of you and served piping hot.',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      'stall-locho-02': <Review>[
        Review(
          id: 'rev-3',
          stallId: 'stall-locho-02',
          authorUid: 'user-103',
          authorName: 'Rohan Desai',
          tasteRating: 5.0,
          hygieneRating: 4.8,
          comment: 'Melt-in-mouth butter locho! Worth crossing town for.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    };
  }
}
