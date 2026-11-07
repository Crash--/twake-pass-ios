import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - LandingView

/// A view that allows the user to input their email address to begin the login flow,
/// or allows the user to navigate to the account creation flow.
///
struct LandingView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LandingState, LandingAction, LandingEffect>

    /// Opens the Twake sign-up page in the system browser.
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            mainContent
            profileSwitcher
        }
        .navigationBarTitle(Localizations.bitwarden, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !store.state.profileSwitcherState.accounts.isEmpty {
                    profileSwitcherToolbarItem
                }
            }
        }
        .task {
            await store.perform(.appeared)
        }
        .toast(store.binding(
            get: \.toast,
            send: LandingAction.toastShown,
        ))
    }

    // MARK: Private Views

    /// The Toolbar item for the profile switcher view
    private var profileSwitcherToolbarItem: some View {
        ProfileSwitcherToolbarView(
            store: store.child(
                state: { state in
                    state.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcher(action)
                },
                mapEffect: { effect in
                    .profileSwitcher(effect)
                },
            ),
        )
    }

    /// A view that displays the ability to add or switch between account profiles
    private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { mainState in
                    mainState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcher(action)
                },
                mapEffect: { profileEffect in
                    .profileSwitcher(profileEffect)
                },
            ),
        )
    }

    /// The main content of the view
    private var mainContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Image(decorative: Asset.Images.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .padding(.horizontal, 12)

                Spacer(minLength: 24)

                landingDetails
            }
            .padding(.bottom, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false, showsIndicators: false)
        }
    }

    /// The section of the view containing input fields, and action buttons.
    private var landingDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(Localizations.twakeLogInTitle)
                .styleGuide(.title2, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                BitwardenTextField(
                    title: Localizations.emailAddress,
                    text: store.binding(
                        get: \.email,
                        send: LandingAction.emailChanged,
                    ),
                    accessibilityIdentifier: "LoginEmailAddressEntry",
                    footerContent: {
                        Text(Localizations.twakeServerX(
                            store.state.serverHost ?? store.state.region.baseURLDescription,
                        ))
                            .styleGuide(.subheadline)
                            .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("TwakeServerLabel")
                            .padding(.vertical, 14)
                    },
                )
                .textFieldConfiguration(.email)
                .onSubmit {
                    guard store.state.isContinueButtonEnabled else { return }
                    Task { await store.perform(.continuePressed) }
                }

                BitwardenToggle(Localizations.rememberMe, isOn: store.binding(
                    get: { $0.isRememberMeOn },
                    send: { .rememberMeChanged($0) },
                ))
                .accessibilityIdentifier("RememberMeSwitch")
                .contentBlock()
            }

            VStack(spacing: 12) {
                AsyncButton(Localizations.twakeLogInWithTwake) {
                    await store.perform(.twakeSsoPressed)
                }
                .accessibilityIdentifier("TwakeSsoButton")
                .disabled(!store.state.isContinueButtonEnabled)
                .buttonStyle(.primary())

                AsyncButton(Localizations.twakeLogInWithMasterPassword) {
                    await store.perform(.continuePressed)
                }
                .accessibilityIdentifier("ContinueButton")
                .disabled(!store.state.isContinueButtonEnabled)
                .buttonStyle(.secondary())
            }

            VStack(spacing: 4) {
                Button(Localizations.twakeSignUp) {
                    openURL(URL(string: "https://pass-signup.twake.valmoriq.fr")!)
                }
                .accessibilityIdentifier("CreateAccountButton")

                AsyncButton(Localizations.twakeLogInWithOrganizationServer) {
                    await store.perform(.organizationServerPressed)
                }
                .accessibilityIdentifier("TwakeOrganizationServerButton")
            }
            .buttonStyle(.bitwardenBorderless)
            .frame(maxWidth: .infinity, alignment: .center)

            Button {
                store.send(.showPreLoginSettings)
            } label: {
                Label(Localizations.appSettings, image: SharedAsset.Icons.cog16.swiftUIImage)
            }
            .accessibilityIdentifier("AppSettingsButton")
            .buttonStyle(.bitwardenBorderless)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty Email") {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                    ),
                ),
            ),
        )
    }
}

#Preview("Example Email") {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "email@example.com",
                        isRememberMeOn: true,
                    ),
                ),
            ),
        )
    }
}

#Preview("Profiles Closed") {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                        profileSwitcherState: ProfileSwitcherState.singleAccountHidden,
                    ),
                ),
            ),
        )
    }
}

#Preview("Profiles Open") {
    NavigationView {
        LandingView(
            store: Store(
                processor: StateProcessor(
                    state: LandingState(
                        email: "",
                        isRememberMeOn: false,
                        profileSwitcherState: ProfileSwitcherState.singleAccount,
                    ),
                ),
            ),
        )
    }
}
#endif
