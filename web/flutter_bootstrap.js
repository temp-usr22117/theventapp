{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const engine = await engineInitializer.initializeEngine();
    const appRunner = await engine.runApp();
    const splash = document.getElementById('thevent-splash');
    if (splash) {
      splash.style.opacity = '0';
      setTimeout(function() {
        splash.remove();
      }, 350);
    }
  }
});
