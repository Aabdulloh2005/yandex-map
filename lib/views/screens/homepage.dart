import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lesson74yandex/services/yandex_service.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late YandexMapController mapController;
  List<MapObject> polylines = [];
  Point? myCurrentLocation;
  Position? _currentLocation;
  LocationPermission? permission;
  final YandexSearch yandexSearch = YandexSearch();
  final TextEditingController _searchTextController = TextEditingController();
  double searchHeight = 250;

  List<SuggestItem> _suggestionList = [];
  final Point najotTalim = const Point(
    latitude: 41.2856806,
    longitude: 69.2034646,
  );

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<SuggestSessionResult> _suggest() async {
    final resultWithSession = await YandexSuggest.getSuggestions(
      text: _searchTextController.text,
      boundingBox: const BoundingBox(
        northEast: Point(latitude: 56.0421, longitude: 38.0284),
        southWest: Point(latitude: 55.5143, longitude: 37.24841),
      ),
      suggestOptions: const SuggestOptions(
        suggestType: SuggestType.geo,
        suggestWords: true,
        userPosition: Point(latitude: 56.0321, longitude: 38),
      ),
    );

    return await resultWithSession.$2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            nightModeEnabled: true,
            onMapCreated: (controller) {
              mapController = controller;
              mapController.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: najotTalim,
                    zoom: 17,
                  ),
                ),
              );
              setState(() {});
            },
            onMapLongTap: (point) async {
              setState(() {
                myCurrentLocation = point;
              });
              polylines = await YandexService.getDirection(
                  najotTalim, myCurrentLocation!,
                  mode: '');
            },
            onCameraPositionChanged: (
              CameraPosition position,
              CameraUpdateReason reason,
              bool finished,
            ) async {
              if (finished && myCurrentLocation != null) {
                polylines = await YandexService.getDirection(
                    najotTalim, myCurrentLocation!,
                    mode: '');
                setState(() {});
              }
            },
            mapType: MapType.vector,
            mapObjects: [
              PlacemarkMapObject(
                mapId: const MapObjectId("najotTalim"),
                point: najotTalim,
                opacity: 1,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    scale: 0.2,
                    image: BitmapDescriptor.fromAssetImage(
                      "assets/images/loc.png",
                    ),
                  ),
                ),
              ),
              if (myCurrentLocation != null)
                PlacemarkMapObject(
                  opacity: 1,
                  mapId: const MapObjectId("myCurrentLocation"),
                  point: myCurrentLocation!,
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                      scale: 0.2,
                      image: BitmapDescriptor.fromAssetImage(
                          "assets/images/location.png"),
                    ),
                  ),
                ),
              ...polylines,
            ],
          ),
          Positioned(
            top: 70,
            left: 10,
            right: 10,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _suggestionList.isNotEmpty ? searchHeight : 0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: ListView.builder(
                itemCount: _suggestionList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      setState(() {
                        searchHeight = 0;
                        myCurrentLocation = _suggestionList[index].center;
                      });

                      mapController.moveCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: myCurrentLocation!,
                            zoom: 17,
                          ),
                        ),
                        animation: const MapAnimation(
                          type: MapAnimationType.smooth,
                          duration: 1.5,
                        ),
                      );
                    },
                    title: Text(
                      _suggestionList[index].title,
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      _suggestionList[index].subtitle!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixIcon: _suggestionList.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchTextController.text = "";
                                myCurrentLocation = null;
                                polylines = [];
                                _suggestionList = [];
                              });
                            },
                            child: const Icon(CupertinoIcons.clear_fill,
                                color: Colors.grey),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.location_on_rounded,
                        color: Colors.red),
                    hintText: "Search for a place and address",
                    hintStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  controller: _searchTextController,
                  onChanged: (value) async {
                    final res = await _suggest();
                    if (res.items != null) {
                      setState(() {
                        _suggestionList = res.items!.toSet().toList();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: MediaQuery.of(context).size.height / 2,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () {
                    mapController.moveCamera(
                      CameraUpdate.zoomIn(),
                      animation: const MapAnimation(
                        type: MapAnimationType.smooth,
                        duration: 1,
                      ),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  onPressed: () {
                    mapController.moveCamera(
                      CameraUpdate.zoomOut(),
                      animation: const MapAnimation(
                        type: MapAnimationType.smooth,
                        duration: 1,
                      ),
                    );
                  },
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: () async {
                _currentLocation = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                final Point currentPoint = Point(
                  latitude: _currentLocation!.latitude,
                  longitude: _currentLocation!.longitude,
                );
                mapController.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: currentPoint, zoom: 16),
                  ),
                  animation: const MapAnimation(
                    type: MapAnimationType.smooth,
                    duration: 1.5,
                  ),
                );
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
