class Contact {
  final int id;
  final String? whatsAppNumber;
  final String? facebookPage;
  final String? youTubeChannel;
  final String? tiktokChannel;

  Contact({
    required this.id,
    this.whatsAppNumber,
    this.facebookPage,
    this.youTubeChannel,
    this.tiktokChannel,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['Id'] ?? json['id'] ?? 0,
      whatsAppNumber: json['WhatsApp_Number'] ?? json['whatsApp_Number'],
      facebookPage: json['Facebook_Page'] ?? json['facebook_Page'],
      youTubeChannel: json['YouTube_Channel'] ?? json['youTube_Channel'],
      tiktokChannel: json['TiktokChannel'] ?? json['tiktokChannel'],
    );
  }
}

class ContactResponse {
  final bool success;
  final String? message;
  final List<Contact> contacts;

  ContactResponse({
    required this.success,
    this.message,
    required this.contacts,
  });

  factory ContactResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    List<Contact> contactsList = [];
    
    if (data is List) {
      contactsList = data.map((item) => Contact.fromJson(item)).toList();
    } else if (data is Map && data['contacts'] != null) {
      contactsList = (data['contacts'] as List)
          .map((item) => Contact.fromJson(item))
          .toList();
    }
    
    return ContactResponse(
      success: json['success'] ?? true,
      message: json['message'],
      contacts: contactsList,
    );
  }
}


