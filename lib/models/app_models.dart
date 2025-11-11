import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? address;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.address,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      address: json['address'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'lat': lat,
      'lng': lng,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? phone,
    String? role,
    String? address,
    double? lat,
    double? lng,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt,
    );
  }
}

class Technician {
  final String id;
  final String userId;
  final User? user;
  final List<String> skills;
  final bool isAvailable;
  final Map<String, dynamic>? location;
  final int? rating;
  final int? totalJobs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Technician({
    required this.id,
    required this.userId,
    this.user,
    required this.skills,
    required this.isAvailable,
    this.location,
    this.rating,
    this.totalJobs,
    this.createdAt,
    this.updatedAt,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    // Handle user field - can be String (ID) or Map (populated object)
    String userId;
    User? user;
    if (json['user'] is String) {
      userId = json['user'];
      user = null;
    } else if (json['user'] is Map) {
      final userMap = json['user'] as Map<String, dynamic>;
      userId = userMap['_id'] ?? userMap['id'] ?? '';
      user = User.fromJson(userMap);
    } else {
      userId = '';
      user = null;
    }

    return Technician(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      user: user,
      skills: List<String>.from(json['skills'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      location: json['location'],
      rating: json['rating']?.toInt(),
      totalJobs: json['totalJobs']?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'skills': skills,
      'isAvailable': isAvailable,
      'location': location,
      'rating': rating,
      'totalJobs': totalJobs,
    };
  }

  Technician copyWith({
    List<String>? skills,
    bool? isAvailable,
    Map<String, dynamic>? location,
    User? user,
  }) {
    return Technician(
      id: id,
      userId: userId,
      user: user ?? this.user,
      skills: skills ?? this.skills,
      isAvailable: isAvailable ?? this.isAvailable,
      location: location ?? this.location,
      rating: rating,
      totalJobs: totalJobs,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Booking {
  final String id;
  final String userId;
  final User? user;
  final String? technicianId;
  final Technician? technician;
  final String serviceType;
  final Map<String, dynamic>? location;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? etaMinutes;
  final double? totalCost;
  final String? notes;
  final int? ratingScore;
  final String? ratingReview;
  final DateTime? ratedAt;

  Booking({
    required this.id,
    required this.userId,
    this.user,
    this.technicianId,
    this.technician,
    required this.serviceType,
    required this.location,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.etaMinutes,
    this.totalCost,
    this.notes,
    this.ratingScore,
    this.ratingReview,
    this.ratedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle user field - can be String (ID) or Map (populated object)
    String userId;
    User? user;
    if (json['user'] is String) {
      userId = json['user'];
      user = null;
    } else if (json['user'] is Map) {
      final userMap = json['user'] as Map<String, dynamic>;
      userId = userMap['_id'] ?? userMap['id'] ?? '';
      user = User.fromJson(userMap);
    } else {
      userId = '';
      user = null;
    }

    // Handle technician field - can be String (ID) or Map (populated object)
    String? technicianId;
    Technician? technician;
    if (json['technician'] is String) {
      technicianId = json['technician'];
      technician = null;
    } else if (json['technician'] is Map) {
      final techMap = json['technician'] as Map<String, dynamic>;
      technicianId = techMap['_id'] ?? techMap['id'] ?? '';
      technician = Technician.fromJson(techMap);
    } else {
      technicianId = null;
      technician = null;
    }

    // Parse createdAt - handle both createdAt and requestedAt fields
    DateTime createdAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      } else if (json['requestedAt'] != null) {
        createdAt = DateTime.parse(json['requestedAt']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    // Parse rating if exists
    int? ratingScore;
    String? ratingReview;
    DateTime? ratedAt;
    if (json['rating'] != null && json['rating'] is Map) {
      final rating = json['rating'] as Map<String, dynamic>;
      ratingScore = rating['score']?.toInt();
      ratingReview = rating['review'];
      if (rating['ratedAt'] != null) {
        try {
          ratedAt = DateTime.parse(rating['ratedAt']);
        } catch (e) {
          ratedAt = null;
        }
      }
    }

    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      user: user,
      technicianId: technicianId,
      technician: technician,
      serviceType: json['serviceType'] ?? '',
      location: json['location'] != null ? Map<String, dynamic>.from(json['location']) : {},
      status: json['status'] ?? 'requested',
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      etaMinutes: json['etaMinutes']?.toInt(),
      totalCost: (json['totalCost'] ?? json['priceEstimate'])?.toDouble(),
      notes: json['notes'],
      ratingScore: ratingScore,
      ratingReview: ratingReview,
      ratedAt: ratedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'technician': technicianId,
      'serviceType': serviceType,
      'location': location,
      'status': status,
      'etaMinutes': etaMinutes,
      'totalCost': totalCost,
      'notes': notes,
    };
  }

  String getStatusDisplay() {
    switch (status) {
      case 'requested':
        return 'Requested';
      case 'matched':
        return 'Technician Matched';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'matched':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get hasRating => ratingScore != null;

  Booking copyWith({
    String? status,
    int? etaMinutes,
    double? totalCost,
    String? notes,
    Technician? technician,
    int? ratingScore,
    String? ratingReview,
    DateTime? ratedAt,
  }) {
    return Booking(
      id: id,
      userId: userId,
      user: user,
      technicianId: technician?.id ?? technicianId,
      technician: technician ?? this.technician,
      serviceType: serviceType,
      location: location,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? updatedAt,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      ratingScore: ratingScore ?? this.ratingScore,
      ratingReview: ratingReview ?? this.ratingReview,
      ratedAt: ratedAt ?? this.ratedAt,
    );
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class SystemStats {
  final int totalUsers;
  final int totalTechnicians;
  final int totalBookings;
  final int activeBookings;
  final int completedBookings;

  SystemStats({
    required this.totalUsers,
    required this.totalTechnicians,
    required this.totalBookings,
    required this.activeBookings,
    required this.completedBookings,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalUsers: (json['totalUsers'] ?? 0).toInt(),
      totalTechnicians: (json['totalTechnicians'] ?? 0).toInt(),
      totalBookings: (json['totalBookings'] ?? 0).toInt(),
      activeBookings: (json['activeBookings'] ?? 0).toInt(),
      completedBookings: (json['completedBookings'] ?? 0).toInt(),
    );
  }
}
