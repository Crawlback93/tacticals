import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Opens [url] in a popup browser window (no browser chrome, positioned on top).
void openPopupWindow(String url) {
  web.window.open(
    url,
    'TactBoardWindow',
    'popup=1,width=1280,height=800,top=50,left=50,resizable=yes,scrollbars=no',
  );
}

/// Registers a beforeunload handler.
/// [hasUnsavedChanges] is called at the moment the user tries to leave —
/// only if it returns true will the browser show the "Leave site?" dialog.
/// Returns a callback to remove the listener.
void Function() registerBeforeUnload(bool Function() hasUnsavedChanges) {
  final handler = (web.BeforeUnloadEvent event) {
    if (hasUnsavedChanges()) {
      event.returnValue = 'Changes may not be saved.';
    }
  }.toJS;

  web.window.addEventListener('beforeunload', handler);
  return () => web.window.removeEventListener('beforeunload', handler);
}
