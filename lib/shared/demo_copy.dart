import 'widgets/demo_note.dart';

/// Centralizes demo/simulation disclaimer copy that doesn't fit the
/// [DemoNote] widget (toast messages, button labels, inline rich text).
/// Every constant is gated by [kShowDemoNotes] so flipping that one flag
/// when real backend services go live swaps every disclaimer below for its
/// neutral, production-appropriate counterpart in one place.
abstract final class DemoCopy {
  // Auth
  static const String verifyEmailNoticeAfter = kShowDemoNotes
      ? '. This is an interactive design preview only.'
      : '.';
  static const String verifyEmailContinueLabel = kShowDemoNotes
      ? 'Continue to demo'
      : 'Continue';
  static const String verifyEmailToast = kShowDemoNotes
      ? 'Verification simulated'
      : 'Email verified';
  static const String verifyEmailResendToast = kShowDemoNotes
      ? 'No real email is sent in this prototype'
      : 'Verification email sent';
  static const String resetSentSubtitle = kShowDemoNotes
      ? 'Your password-reset instructions are ready in this demo flow.'
      : 'Your password-reset instructions are on their way.';
  static const String resetSentNoticeAfter = kShowDemoNotes
      ? '. No email has been sent by this prototype.'
      : '.';
  static const String loginSuccessToast = kShowDemoNotes
      ? 'Signed in to demo account'
      : 'Signed in';

  // Profile
  static const String deleteAccountModalBody = kShowDemoNotes
      ? 'This demo does not connect to a live user account. No data '
            'will be deleted.'
      : 'Account deletion is final and cannot be undone.';
  static const String deleteAccountWarning = kShowDemoNotes
      ? 'This is a visual preview only. No real user account or cloud '
            'data will be deleted.'
      : 'Deleting your account will permanently remove your data.';
  static const String editProfileSavedToast = kShowDemoNotes
      ? 'Profile updated in demo'
      : 'Profile updated';
  static const String editProfileHelper = kShowDemoNotes
      ? 'Changes here are saved only in this demo session.'
      : 'Changes are saved to your profile.';
  static const String planIntroBody = kShowDemoNotes
      ? 'These are illustrative plan periods; prices have not '
            'been approved.'
      : 'Choose the billing period that works for you.';
  static const String planWarning = kShowDemoNotes
      ? 'No purchase is available in this prototype. Final plans depend '
            'on AI operating costs.'
      : 'Pricing is subject to change.';
  static const String planContinueLabel = kShowDemoNotes
      ? 'Continue · Preview only'
      : 'Continue';
  static const String settingsSignOutSubtitle = kShowDemoNotes
      ? 'Leave the current demo session'
      : 'Sign out of your account';
  static const String signoutButtonLabel = kShowDemoNotes
      ? 'Sign out · Demo'
      : 'Sign out';
  static const String signoutToast = kShowDemoNotes
      ? 'Signed out of demo preview'
      : 'Signed out';
  static const String subscriptionRestoreLabel = kShowDemoNotes
      ? 'Restore purchases · Demo'
      : 'Restore purchases';
  static const String subscriptionRestoreToast = kShowDemoNotes
      ? 'No purchases to restore in this demo'
      : 'No purchases to restore';
  static const String subscriptionHelper = kShowDemoNotes
      ? "The prototype doesn't communicate with app stores or process "
            'real purchases.'
      : 'Manage your subscription from your app store account.';
  static const String supportDetailBody = kShowDemoNotes
      ? 'Official support channels, policies and terms are not '
            'included in this design prototype.'
      : 'Official support channels, policies and terms are coming soon.';
  static const String weatherHelper = kShowDemoNotes
      ? 'No location data is accessed by this offline prototype.'
      : 'Location data is only used to personalize recommendations.';

  // Packing
  static const String packingPreviewDemoClause = kShowDemoNotes
      ? ' Suggestions are a demo, not live AI.'
      : '';

  // Wardrobe
  static const String analyzingCaption = kShowDemoNotes
      ? 'DEMO ANALYSIS'
      : 'ANALYZING';

  // Shopping
  static const String shPhaseNoLiveProducts = kShowDemoNotes
      ? 'No live products are shown here.'
      : 'Live products are on the way.';
}
