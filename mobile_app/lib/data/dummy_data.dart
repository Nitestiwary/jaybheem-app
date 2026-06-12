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
    'https://upload.wikimedia.org/wikipedia/commons/c/c3/Dr._Bhimrao_Ambedkar.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/e/e0/Buddha_in_Sarnath_Museum_%28Dhammajak_Mutra%29.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/8/85/Mahabodhi_Temple_Bodh_Gaya_India.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/3/3f/Lotus_flower_in_a_pond.jpg',
  ];

  // A public domain sample video to use as a dummy short
  static final List<String> _videoUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
  ];

  static List<StatusModel> generateStatuses() {
    List<StatusModel> statuses = [];
    int idCounter = 1;

    for (int i = 0; i < 50; i++) {
      String category = categories[i % categories.length];
      String caption = _getDummyTextForCategory(category, i);
      
      // Every 3rd post is a video, rest are images
      bool isVideo = i % 3 == 0;
      
      statuses.add(StatusModel(
        id: 'dummy_$idCounter',
        text: caption,
        imageUrl: !isVideo ? _imageUrls[i % _imageUrls.length] : null,
        videoUrl: isVideo ? _videoUrls[i % _videoUrls.length] : null,
        category: category,
        type: isVideo ? 'video' : 'image',
        shareCount: (i * 12) % 1500,
        viewCount: (i * 50) % 5000,
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
