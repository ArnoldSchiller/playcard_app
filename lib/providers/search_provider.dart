import 'package:playcard_app/config/config.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<StreamItem> _searchResults = [];
  bool _isLoadingSearch = false;
  String? _errorMessageSearch;

  TextEditingController get searchController => _searchController;
  List<StreamItem> get searchResults => _searchResults;
  bool get isLoadingSearch => _isLoadingSearch;
  String? get errorMessageSearch => _errorMessageSearch;
  bool get isSearching => _searchController.text.isNotEmpty;

  SearchProvider() {
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _search(query);
    } else {
      _searchResults = [];
      _errorMessageSearch = null;
      notifyListeners();
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;

    _isLoadingSearch = true;
    _errorMessageSearch = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> results = await _apiService.fetchIndex(search: query, structured: false);
      _searchResults = results
          .map((json) {
            final song = StreamItem.fromJson({...json, 'isRadioStream': false});
            // Vervollständige relative streamUrl für Suchergebnisse
            final streamUrl = song.streamUrl.isNotEmpty && !song.streamUrl.startsWith('http')
                ? '$kBaseUrl${song.streamUrl}'
                : song.streamUrl;
            return StreamItem(
              name: song.name,
              artist: song.artist,
              relativePath: song.relativePath,
              streamUrl: streamUrl,
              coverImageUrl: song.coverImageUrl,
            );
          })
          .toList();
    } catch (e) {
      _errorMessageSearch = e.toString();
      _searchResults = [];
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
