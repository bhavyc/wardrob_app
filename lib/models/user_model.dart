enum UserRole {
  renter,
  lister,
  admin,
  hubPartner,
}

extension UserRoleExtension on UserRole {
  String toPrismaString() {
    switch (this) {
      case UserRole.renter:
        return 'RENTER';
      case UserRole.lister:
        return 'LISTER';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.hubPartner:
        return 'HUB_PARTNER';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'LISTER':
        return UserRole.lister;
      case 'ADMIN':
        return UserRole.admin;
      case 'HUB_PARTNER':
        return UserRole.hubPartner;
      case 'RENTER':
      default:
        return UserRole.renter;
    }
  }
}

enum IDVerificationStatus {
  notSubmitted,
  pending,
  approved,
  rejected,
}

extension IDVerificationStatusExtension on IDVerificationStatus {
  static IDVerificationStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return IDVerificationStatus.pending;
      case 'APPROVED':
        return IDVerificationStatus.approved;
      case 'REJECTED':
        return IDVerificationStatus.rejected;
      case 'NOT_SUBMITTED':
      default:
        return IDVerificationStatus.notSubmitted;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final bool idVerified;
  final IDVerificationStatus idVerificationStatus;
  final double walletBalance;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.idVerified = false,
    this.idVerificationStatus = IDVerificationStatus.notSubmitted,
    this.walletBalance = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: UserRoleExtension.fromString(json['role']?.toString()),
      idVerified: json['idVerified'] == true,
      idVerificationStatus: IDVerificationStatusExtension.fromString(
        json['idVerificationStatus']?.toString(),
      ),
      walletBalance: (json['walletBalance'] != null)
          ? double.tryParse(json['walletBalance'].toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toPrismaString(),
      'idVerified': idVerified,
      'idVerificationStatus': idVerificationStatus.name,
      'walletBalance': walletBalance,
    };
  }
}
