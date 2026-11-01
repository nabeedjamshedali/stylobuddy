import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';

class OutfitsState {
  const OutfitsState({this.outfits = const [], this.wearLog = const []});

  final List<Outfit> outfits;
  final List<WearEvent> wearLog;

  OutfitsState copyWith({List<Outfit>? outfits, List<WearEvent>? wearLog}) =>
      OutfitsState(
        outfits: outfits ?? this.outfits,
        wearLog: wearLog ?? this.wearLog,
      );
}
