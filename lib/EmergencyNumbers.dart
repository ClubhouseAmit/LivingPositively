import 'package:flutter/material.dart';

class Country {
  final String id;
  final List<String> countryCodes;
  final List<Map<String, dynamic>> emergencyNumbers;
  final bool isDefaultPicker;
  final bool isDefaultEmergency;

  const Country({
    required this.id,
    required this.countryCodes,
    required this.emergencyNumbers,
    this.isDefaultPicker = false,
    this.isDefaultEmergency = false,
  });
}

const Map<String, dynamic> elemSupportOption = {
  "name": "Elem עלם",
  "number": "0546786776",
  "whatsappNumber": "972546786776",
  "link": "https://yelem.org.il/",
  "description": "Support for children and teens",
  "descriptionHe": "סיוע לילדים ובני נוער",
  "icon": Icons.chat,
  "whatsapp": true,
  "canCall": false,
};

const List<String> euCountryCodes = [
  'AT',
  'BE',
  'BG',
  'HR',
  'CY',
  'CZ',
  'DK',
  'EE',
  'FI',
  'FR',
  'DE',
  'GR',
  'HU',
  'IE',
  'IT',
  'LV',
  'LT',
  'LU',
  'MT',
  'NL',
  'PL',
  'PT',
  'RO',
  'SK',
  'SI',
  'ES',
  'SE',
];

final Map<String, Country> countries = {
  "israel": Country(
    id: "israel",
    countryCodes: ["IL"],
    isDefaultPicker: true,
    emergencyNumbers: [
    {
      "name": "105",
      "number": "105",
      "whatsappNumber": "0521210105",
      "link": "",
      "description": "המטה הלאומי להגנת ילדים ברשת",
      "icon": Icons.phone,
      "whatsapp": true,
      "canCall": true,
    },
    {
      "name": "ער\"ן",
      "number": "1201",
      "whatsappNumber": "972528451201",
      "link": "",
      "description": "עזרה ראשונה נפשית",
      "icon": Icons.phone,
      "whatsapp": true,
      "canCall": true,
    },
    {
      "name": "סה\"ר",
      "number": "0559571399",
      "link": "https://sahar.org.il/",
      "description": "סיוע והקשבה ברשת",
      "icon": Icons.phone,
      "whatsapp": true,
      "canCall": false,
    },
    {
      "name": "משטרה",
      "number": "100",
      "link": "",
      "description": "",
      "icon": Icons.phone,
      "whatsapp": false,
      "canCall": true,
    }
    ],
  ),
  "usa": Country(
    id: "usa",
    countryCodes: ["US"],
    emergencyNumbers: [
    {
      "name": "Emergency",
      "number": "911",
      "link": "",
      "description": "Call: 911",
      "whatsapp": false,
      "icon": Icons.phone,
      "canCall": true,
    },
    {
      "name": "Veterans Crisis Line",
      "number": "988",
      "link": "https://www.veteranscrisisline.net/get-help-now/chat/",
      "linkType": "chat",
      "textNumber": "838255",
      "description": "Call: 988 and Press 1 / Text: 838255 / Chat online: veteranscrisisline.net/get-help-now/chat/",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "The Trevor Project (for LGBTQ+ youth)",
      "number": "18664887386",
      "link": "https://www.thetrevorproject.org/get-help/",
      "linkType": "chat",
      "textNumber": "678678",
      "textMessage": "START",
      "description": "Call: 1-866-488-7386 / Text: START to 678678 / Chat online: thetrevorproject.org/get-help/",
      "descriptionHe": "מרכז לנוער להטב\"ק+",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "988 Suicide & Crisis Lifeline",
      "number": "988",
      "link": "https://988lifeline.org/chat/",
      "linkType": "chat",
      "textNumber": "988",
      "description": "Call or Text: 988 / Chat online: 988lifeline.org/chat/",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "Crisis Text Line",
      "number": "741741",
      "link": "https://www.crisistextline.org/",
      "textNumber": "741741",
      "textMessage": "HOME",
      "description": "Text: HOME to 741741",
      "whatsapp": false,
      "canCall": false,
      "icon": Icons.sms
    }
    ],
  ),
  "uk": Country(
    id: "uk",
    countryCodes: ["GB"],
    emergencyNumbers: [
    {
      "name": "Emergency",
      "number": "999",
      "link": "",
      "description": "Call: 999",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.phone
    },
    {
      "name": "Samaritans",
      "number": "116123",
      "link": "http://samaritans.org/how-we-can-help/contact-samaritan/",
      "email": "jo@samaritans.org",
      "description": "Call: 116 123 (UK and ROI) / Email: jo@samaritans.org",
      "descriptionHe": "סמריטנס היא עמותה למניעת התאבדות.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "Shout",
      "number": "85258",
      "link": "",
      "textNumber": "85258",
      "textMessage": "SHOUT",
      "description": "Text: SHOUT to 85258",
      "whatsapp": false,
      "canCall": false,
      "icon": Icons.sms
    },
    {
      "name": "CALM (Campaign Against Living Miserably, for men)",
      "number": "0800585858",
      "link": "https://www.thecalmzone.net/",
      "description": "Call: 0800 58 58 58 (5pm to midnight)",
      "descriptionHe": "תנועה מובילה למאבק בהתאבדות בקרב גברים.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "Papyrus (for people under 35)",
      "number": "08000684141",
      "link": "",
      "textNumber": "88247",
      "description": "Call: 0800 068 4141 / Text: 88247",
      "descriptionHe": "פאפירוס מוקדשת למניעת התאבדות בקרב צעירים.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.sms
    }
    ],
  ),
  "eu": Country(
    id: "eu",
    countryCodes: euCountryCodes,
    isDefaultEmergency: true,
    emergencyNumbers: [
    {
      "name": "European Emergency Number",
      "number": "112",
      "link": "",
      "description":
          "Call: 112 / Note: Many EU countries have their own national helplines. We recommend checking with local authorities for country-specific resources.",
      "descriptionHe": "צריך עזרה? 112 הוא מספר החירום שלך להצלת חיים!",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.phone
    },
    {
      "name": "Mental Health Europe",
      "link": "https://mhe-sme.org/",
      "description":
          "Website: mhe-sme.org / Provides links to mental health services across Europe.",
      "descriptionHe": "הארגון המוביל לבריאות הנפש ולרווחה.",
      "whatsapp": false,
      "number": "",
      "canCall": false,
      "icon": Icons.link
    }
    ],
  ),
  "australia": Country(
    id: "australia",
    countryCodes: ["AU"],
    emergencyNumbers: [
    {
      "name": "Emergency",
      "number": "000",
      "link": "",
      "description": "Call: 000",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.phone
    },
    {
      "name": "Lifeline Australia",
      "number": "131114",
      "link": "https://www.lifeline.org.au/crisis-chat/",
      "linkType": "chat",
      "textNumber": "0477131114",
      "description":
          "Call: 13 11 14 / Text: 0477 13 11 14 / Chat online: lifeline.org.au/crisis-chat/",
      "descriptionHe": "תמיכה במשברים ומניעת התאבדות 24/7.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "Beyond Blue",
      "number": "1300224636",
      "link": "https://www.beyondblue.org.au/get-support/talk-to-a-counsellor",
      "linkType": "chat",
      "description":
          "Call: 1300 22 4636 / Chat online: beyondblue.org.au/get-support/talk-to-a-counsellor",
      "descriptionHe": "מקור מידע אמין לבריאות הנפש.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "Kids Helpline (for people aged 5-25)",
      "number": "1800551800",
      "link": "https://kidshelpline.com.au/",
      "description": "Call: 1800 55 1800",
      "descriptionHe": "ייעוץ 24/7 לצעירים בגילאי 5 עד 25.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    },
    {
      "name": "MensLine Australia",
      "number": "1300789978",
      "link": "https://mensline.org.au/",
      "description": "Call: 1300 78 99 78",
      "descriptionHe": "שירות ייעוץ טלפוני ומקוון לגברים.",
      "whatsapp": false,
      "canCall": true,
      "icon": Icons.chat
    }
    ],
  )
};

List<String> get countryPickerCodes => countries.values
    .expand((country) => country.countryCodes)
    .toList();

Country get defaultPickerCountry => countries.values.firstWhere(
    (country) => country.isDefaultPicker,
    orElse: () => countries.values.first);

Country get defaultEmergencyCountry => countries.values.firstWhere(
    (country) => country.isDefaultEmergency,
    orElse: () => countries.values.first);

Country? findCountryByCode(String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized.isEmpty) {
    return null;
  }
  for (final country in countries.values) {
    if (country.countryCodes.contains(normalized)) {
      return country;
    }
  }
  return null;
}
//{"name":, "number":, "link":,"description":,"icon":}
