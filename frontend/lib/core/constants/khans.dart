import 'package:latlong2/latlong.dart';

/// A Khan (district) of Phnom Penh Capital.
class Khan {
  const Khan({
    required this.id,
    required this.en,
    required this.km,
    required this.center,
  });

  final String id;
  final String en;
  final String km;

  /// APPROXIMATE centre point, used only to recentre the map.
  /// TODO(data): replace with official boundary/centroid data.
  final LatLng center;
}

/// The 14 Khans of Phnom Penh.
abstract final class PhnomPenhKhans {
  static const Khan russeyKeo = Khan(
    id: 'russey_keo',
    en: 'Russey Keo',
    km: 'ឫស្សីកែវ',
    center: LatLng(11.5813, 104.9158),
  );

  static const List<Khan> all = [
    Khan(
      id: 'chamkar_mon',
      en: 'Chamkar Mon',
      km: 'ចំការមន',
      center: LatLng(11.5350, 104.9250),
    ),
    Khan(
      id: 'doun_penh',
      en: 'Doun Penh',
      km: 'ដូនពេញ',
      center: LatLng(11.5700, 104.9220),
    ),
    Khan(
      id: 'prampir_meakkakra',
      en: 'Prampir Meakkakra',
      km: 'ប្រាំពីរមករា',
      center: LatLng(11.5560, 104.9050),
    ),
    Khan(
      id: 'tuol_kork',
      en: 'Tuol Kork',
      km: 'ទួលគោក',
      center: LatLng(11.5800, 104.8970),
    ),
    Khan(
      id: 'dangkao',
      en: 'Dangkao',
      km: 'ដង្កោ',
      center: LatLng(11.4900, 104.8500),
    ),
    Khan(
      id: 'mean_chey',
      en: 'Mean Chey',
      km: 'មានជ័យ',
      center: LatLng(11.5150, 104.9150),
    ),
    russeyKeo,
    Khan(
      id: 'sen_sok',
      en: 'Sen Sok',
      km: 'សែនសុខ',
      center: LatLng(11.6000, 104.8700),
    ),
    Khan(
      id: 'pou_senchey',
      en: 'Pou Senchey',
      km: 'ពោធិ៍សែនជ័យ',
      center: LatLng(11.5300, 104.8300),
    ),
    Khan(
      id: 'chroy_changvar',
      en: 'Chroy Changvar',
      km: 'ជ្រោយចង្វារ',
      center: LatLng(11.6000, 104.9400),
    ),
    Khan(
      id: 'prek_pnov',
      en: 'Prek Pnov',
      km: 'ព្រែកព្នៅ',
      center: LatLng(11.6700, 104.8800),
    ),
    Khan(
      id: 'chbar_ampov',
      en: 'Chbar Ampov',
      km: 'ច្បារអំពៅ',
      center: LatLng(11.5300, 104.9500),
    ),
    Khan(
      id: 'boeng_keng_kang',
      en: 'Boeng Keng Kang',
      km: 'បឹងកេងកង',
      center: LatLng(11.5500, 104.9300),
    ),
    Khan(
      id: 'kamboul',
      en: 'Kamboul',
      km: 'កំបូល',
      center: LatLng(11.4900, 104.7900),
    ),
  ];

  static Khan byId(String id) =>
      all.firstWhere((k) => k.id == id, orElse: () => russeyKeo);
}
