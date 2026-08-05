/// Temporary kill switches for nav entry points to features that aren't
/// ready for production yet. Flip to true to bring an entry point back —
/// the route and permission gates underneath it are never touched.
library;

/// AI Assistant (FAB + sidebar) and Unusual Activity (sidebar + drawer).
const bool kShowAiAndFraudNav = false;
