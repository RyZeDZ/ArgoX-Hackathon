import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapZone {
  final LatLng coordinates;
  final Color color;
  final double radius;
  final String label;

  MapZone({
    required this.coordinates,
    required this.color,
    this.radius = 80.0,
    this.label = '',
  });
}