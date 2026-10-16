/// One path per prototype route (`pages.*` in app.js); paths equal the
/// prototype route names. Routes with an id helper expose the bare path as
/// `<name>Path`.
abstract final class AppRoutes {
  static const auth = '/auth';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';
  static const resetSent = '/reset-sent';
  static const verifyEmail = '/verify-email';
  static const builder = '/builder';
  static const manualPreview = '/manual-preview';
  static const calendar = '/calendar';
  static const calendarChoose = '/calendar-choose';
  static const calendarDate = '/calendar-date';
  static const home = '/home';
  static const insights = '/insights';
  static const matching = '/matching';
  static const matchSelect = '/match-select';
  static const matchReview = '/match-review';
  static const matchOptions = '/match-options';
  static const matchingProgress = '/matching-progress';
  static const matchingResults = '/matching-results';
  static const matchingDetail = '/matching-detail';
  static const welcome = '/welcome';
  static const intro = '/intro';
  static const personalize = '/personalize';
  static const packing = '/packing';
  static const newTrip = '/new-trip';
  static const packingPreview = '/packing-preview';
  static const packingList = '/packing-list';
  static const packingAdd = '/packing-add';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const editStyle = '/edit-style';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const weatherSettings = '/weather-settings';
  static const support = '/support';
  static const supportDetail = '/support-detail';
  static const deleteAccount = '/delete-account';
  static const signout = '/signout';
  static const premium = '/premium';
  static const plan = '/plan';
  static const purchase = '/purchase';
  static const subscription = '/subscription';
  static const saved = '/saved';
  static const savedDetailPath = '/saved-detail';
  static const wearDetailPath = '/wear-detail';
  static const shopping = '/shopping';
  static const shopItem = '/shop-item';
  static const stylist = '/stylist';
  static const occasion = '/occasion';
  static const stylingOptions = '/styling-options';
  static const generating = '/generating';
  static const results = '/results';
  static const resultDetail = '/result-detail';
  static const wardrobe = '/wardrobe';
  static const clothingPath = '/clothing';
  static const editItem = '/edit-item';
  static const filter = '/filter';
  static const import = '/import';
  static const importSource = '/import-source';
  static const batch = '/batch';
  static const analyzing = '/analyzing';
  static const review = '/review';
  static const addConfirm = '/add-confirm';

  static String clothing(String id) => '$clothingPath?id=$id';
  static String savedDetail(int id) => '$savedDetailPath?id=$id';
  static String wearDetail(int id) => '$wearDetailPath?id=$id';

  /// Routes rendered without the bottom navigation.
  static const noNavRoutes = {
    welcome,
    intro,
    personalize,
    auth,
    login,
    signup,
    forgot,
    resetSent,
    verifyEmail,
  };

  static const _wardrobeGroup = {
    '/clothing', '/import', '/batch', '/analyzing', '/review', '/builder',
    '/manual-preview', '/add-confirm', '/filter', '/edit-item',
  };
  static const _stylistGroup = {
    '/stylist', '/occasion', '/generating', '/results', '/result-detail',
    '/matching', '/match-select', '/match-review', '/match-options',
    '/matching-progress', '/matching-results', '/matching-detail',
    '/styling-options',
  };
  static const _savedGroup = {
    '/saved', '/saved-detail', '/wear-detail', '/history', '/sharing',
  };
  static const _profileGroup = {
    '/profile', '/settings', '/edit-profile', '/edit-style', '/notifications',
    '/support', '/premium', '/plan', '/purchase', '/subscription',
  };

  /// Prototype `render()` tab grouping: which bottom tab a location lights up.
  static String tabFor(String location) {
    final path = Uri.parse(location).path;
    if (path == wardrobe || _wardrobeGroup.contains(path)) return wardrobe;
    if (_stylistGroup.contains(path)) return stylist;
    if (_savedGroup.contains(path)) return saved;
    if (_profileGroup.contains(path)) return profile;
    return home;
  }
}
