// MARK: - LandingEffect

/// Effects that can be processed by a `LandingProcessor`.
enum LandingEffect: Equatable {
    /// The vault list appeared on screen.
    case appeared

    /// The continue button was pressed.
    case continuePressed

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// The region button was pressed.
    case regionPressed

    /// The "Log in with Twake" (single sign-on) button was pressed.
    case twakeSsoPressed

    /// The "organization's server" button was pressed.
    case organizationServerPressed
}
