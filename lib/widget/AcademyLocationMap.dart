import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui;

/// 오시는 길: 학원 좌표 중심 지도 + 네이버 지도/길찾기.
class AcademyLocationMap extends StatefulWidget {
  final double height;

  const AcademyLocationMap({Key? key, this.height = 420}) : super(key: key);

  static const String address =
      '경기도 파주시 해올2길 2 태산W타워 7층, 701~703호 (다율동 1044)';
  static const String placeName = '글림아일랜드 어학원';
  static const String naverPlaceId = '1786919953';
  static const double latitude = 37.734168;
  static const double longitude = 126.7304957;

  static String get naverSearchUrl =>
      'https://map.naver.com/p/entry/place/$naverPlaceId?c=$longitude,$latitude,18,0,0,0,dh';

  static String get naverDirectionsUrl =>
      'https://map.naver.com/p/directions/-/-/$longitude,$latitude,${Uri.encodeComponent(placeName)},$naverPlaceId/walk';

  @override
  State<AcademyLocationMap> createState() => _AcademyLocationMapState();
}

class _AcademyLocationMapState extends State<AcademyLocationMap> {
  static const String _viewType = 'academy-location-map-v5';
  static bool _registered = false;

  @override
  void initState() {
    super.initState();
    if (_registered) return;
    _registered = true;
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..srcdoc = _mapHtml()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('title', '글림아일랜드 파주캠퍼스 위치 지도');
        return iframe;
      },
    );
  }

  static String _mapHtml() {
    const lat = AcademyLocationMap.latitude;
    const lng = AcademyLocationMap.longitude;
    const name = AcademyLocationMap.placeName;
    return '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <style>
    html, body, #map { width: 100%; height: 100%; margin: 0; }
    .academy-marker { position: relative; width: 0; height: 0; }
    .academy-dot {
      position: absolute; left: -13px; top: -13px;
      width: 26px; height: 26px; border-radius: 50%;
      background: #e03131; border: 3px solid #fff;
      box-shadow: 0 2px 8px rgba(0,0,0,.35);
    }
    .academy-label {
      position: absolute; left: 18px; top: -22px;
      padding: 6px 10px; background: #fff; color: #111;
      border-radius: 8px; white-space: nowrap;
      font: 700 13px/1.3 "Apple SD Gothic Neo", "Noto Sans KR", sans-serif;
      box-shadow: 0 2px 10px rgba(0,0,0,.22);
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script>
    const map = L.map('map', { scrollWheelZoom: true, zoomControl: true })
      .setView([$lat, $lng], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap'
    }).addTo(map);
    const icon = L.divIcon({
      className: '',
      html: '<div class="academy-marker"><div class="academy-dot"></div><div class="academy-label">$name</div></div>',
      iconSize: [0, 0],
      iconAnchor: [0, 0]
    });
    L.marker([$lat, $lng], { icon: icon, zIndexOffset: 1000 }).addTo(map);
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: HtmlElementView(viewType: _viewType),
          ),
        ),
        SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _mapButton(
              label: '네이버 지도에서 보기',
              filled: true,
              onTap: () => UrlUtil.open(AcademyLocationMap.naverSearchUrl),
            ),
            _mapButton(
              label: '네이버 길찾기',
              filled: false,
              onTap: () => UrlUtil.open(AcademyLocationMap.naverDirectionsUrl),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: filled
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.darkTeal,
                foregroundColor: Palette.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.navy,
                side: BorderSide(color: Palette.grey300),
                padding: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
    );
  }
}
