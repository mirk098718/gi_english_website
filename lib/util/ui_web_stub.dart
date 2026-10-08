class PlatformViewRegistry {
  void registerViewFactory(
    String viewType,
    Object Function(int viewId) viewFactory,
  ) {}
}

final PlatformViewRegistry platformViewRegistry = PlatformViewRegistry();
