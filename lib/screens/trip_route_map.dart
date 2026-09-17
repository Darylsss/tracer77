import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/position.dart' as models;

class TripRouteMap extends StatefulWidget {
  final List<models.Position> positions;

  const TripRouteMap({super.key, required this.positions});

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  AnimationController? _animController;
  int _visibleCount = 0;

  static const Color darkBlue = Color(0xFF0A1A6B);
  static const Color accentBlue = Color(0xFF4A6FE3);

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant TripRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positions != widget.positions) {
      _animController?.dispose();
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (widget.positions.length < 2) {
      _visibleCount = widget.positions.length;
      return;
    }
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.positions.length * 120).clamp(800, 6000)),
    )..addListener(() {
        setState(() {
          _visibleCount = (_animController!.value * widget.positions.length).round().clamp(1, widget.positions.length);
        });
      });
    _visibleCount = 1;
    _animController!.forward();
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.positions.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        color: const Color(0xFFF4F6FA),
        child: const Text(
          'Aucune position pour cette période',
          style: TextStyle(fontFamily: 'Montserrat', color: Colors.black45, fontSize: 12),
        ),
      );
    }

    final visiblePoints = widget.positions
        .take(_visibleCount)
        .map((p) => LatLng(p.lat, p.lng))
        .toList();

    final bounds = _computeBounds(widget.positions);

    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: visiblePoints.first, zoom: 15),
              onMapCreated: (controller) {
                _controller = controller;
                Future.delayed(const Duration(milliseconds: 300), () {
                  _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
                });
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('trajet'),
                  points: visiblePoints,
                  color: accentBlue,
                  width: 4,
                ),
              },
              markers: {
                if (visiblePoints.isNotEmpty)
                  Marker(
                    markerId: const MarkerId('position_actuelle'),
                    position: visiblePoints.last,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
                Marker(
                  markerId: const MarkerId('depart'),
                  position: LatLng(widget.positions.first.lat, widget.positions.first.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: const InfoWindow(title: 'Départ'),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: true,
              liteModeEnabled: false,
            ),
            if (_animController != null && _animController!.isAnimating)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Lecture du trajet…',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, color: darkBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LatLngBounds _computeBounds(List<models.Position> positions) {
    double minLat = positions.first.lat, maxLat = positions.first.lat;
    double minLng = positions.first.lng, maxLng = positions.first.lng;
    for (final p in positions) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}