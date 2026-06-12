import '../models/status_model.dart';

class DummyData {
  static final List<String> categories = [
    'Jai Bhim',
    'Baba Saheb Quotes',
    'Jatav Status',
    'SC/ST Pride',
    'Motivation',
    'Education',
    'Constitution',
    'Success',
    'Bio Lines',
    'DP Status'
  ];

  static final List<String> _imageUrls = [
    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Dr._Bhimrao_Ambedkar.jpg/800px-Dr._Bhimrao_Ambedkar.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/B._R._Ambedkar_in_1950.jpg/800px-B._R._Ambedkar_in_1950.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Lord_Buddha_in_Sarnath.jpg/800px-Lord_Buddha_in_Sarnath.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Dr_B_R_Ambedkar_statue_at_Parliament_of_India.jpg/800px-Dr_B_R_Ambedkar_statue_at_Parliament_of_India.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/B.R._Ambedkar_with_his_family.jpg/800px-B.R._Ambedkar_with_his_family.jpg',
  ];

  static List<StatusModel> generateStatuses() {
    List<StatusModel> statuses = [];
    int idCounter = 1;

    for (int i = 0; i < 50; i++) {
      String category = categories[i % categories.length];
      String text = _getDummyTextForCategory(category, i);
      
      // Every alternate post is an image post
      bool isImage = i % 2 == 0;
      
      statuses.add(StatusModel(
        id: 'dummy_$idCounter',
        text: text,
        imageUrl: isImage ? _imageUrls[i % _imageUrls.length] : null,
        category: category,
        type: isImage ? 'image' : 'text',
        shareCount: (i * 7) % 500,
        viewCount: (i * 23) % 1500,
        createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
      ));
      idCounter++;
    }

    return statuses;
  }

  static String _getDummyTextForCategory(String category, int index) {
    switch (category) {
      case 'Jai Bhim':
        return 'Namo Buddhay, Jai Bhim! Following the path of equality and justice shown by Baba Saheb. #JaiBhim';
      case 'Baba Saheb Quotes':
        return '"Life should be great rather than long." - Dr. B.R. Ambedkar. Remembering his powerful words.';
      case 'Jatav Status':
        return 'Proud of our heritage, standing tall and strong. Jatav Pride! 💪 #Jatav';
      case 'SC/ST Pride':
        return 'Unity is our strength. We rise by lifting others. SC/ST community pride! #Pride';
      case 'Motivation':
        return 'Educate, Agitate, Organize. The mantra for success and freedom. Keep pushing forward!';
      case 'Education':
        return 'Education is the milk of a tigress. The one who drinks it will definitely roar! 📚✏️';
      case 'Constitution':
        return 'Our Constitution is a ray of hope: H for Harmony, O for Opportunity, P for People\'s Participation, E for Equality. 🇮🇳';
      case 'Success':
        return 'Success is not a destination, it is a journey built on hard work and self-belief. Keep walking! 🚀';
      case 'Bio Lines':
        return 'Believer in Equality | Follower of Dr. Ambedkar | Hustler 🌟';
      case 'DP Status':
        return 'My DP says it all - Unstoppable and Unshakable. #Profile';
      default:
        return 'Always keep learning and growing! #JaiBhim';
    }
  }
}
