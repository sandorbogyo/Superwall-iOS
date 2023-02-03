//
//  File.swift
//  
//
//  Created by Jake Mor on 10/5/21.
//

import Foundation

/// The objective-c only delegate protocol that handles Superwall lifecycle events.
///
/// The delegate methods receive callbacks from the SDK in response to certain events that happen on the paywall.
///
/// You pass this in when configuring the SDK via ``Superwall/configure(apiKey:delegate:options:completion:)-7fafw``.
///
/// To learn how to conform to the delegate in your app and best practices, see <doc:AdvancedConfiguration>.
@objc(SWKSuperwallDelegate)
public protocol SuperwallDelegateObjc: AnyObject {
  @objc optional func subscriptionController() -> SubscriptionControllerObjc?

  /// Called when the user taps a button on your paywall that has a `data-pw-custom` tag attached.
  ///
  /// To learn more about using this function, see <doc:CustomPaywallButtons>. To learn about the types of tags that
  /// can be attached to elements on your paywall, see [Data Tags](https://docs.superwall.com/docs/data-tags).
  ///
  ///  - Parameter name: The value of the `data-pw-custom` tag in your HTML element that the user selected.
  @MainActor
  @objc optional func handleCustomPaywallAction(withName name: String)

  /// Called right before the paywall is dismissed.
  @MainActor
  @objc optional func willDismissPaywall()

  /// Called right before the paywall is presented.
  @MainActor
  @objc optional func willPresentPaywall()

  /// Called right after the paywall is dismissed.
  @MainActor
  @objc optional func didDismissPaywall()

  /// Called right after the paywall is presented.
  @MainActor
  @objc optional func didPresentPaywall()

  /// Called when the user opens a URL by selecting an element on your paywall that has a `data-pw-open-url` tag.
  ///
  /// - Parameter url: The URL to open
  @MainActor
  @objc optional func willOpenURL(url: URL)

  /// Called when the user taps a deep link in your paywall.
  ///
  /// - Parameter url: The deep link URL to open
  @MainActor
  @objc optional func willOpenDeepLink(url: URL)

  /// Called whenever an internal analytics event is tracked.
  ///
  /// Use this method when you want to track internal analytics events in your own analytics.
  ///
  /// You can switch over `info.event` for a list of possible cases. See <doc:SuperwallEvents> for more info.
  ///
  /// - Parameter info: A `SuperwallEventInfo` object containing an `event` and a `params` parameter.
  @MainActor
  @objc optional func didTrackSuperwallEventInfo(_ info: SuperwallEventInfo)

  /// Called when the property ``Superwall/hasActiveSubscription`` changes.
  ///
  /// This is called whenever the subscription status of the user changes based on the on-device receipt.
  /// You can use this to update the state of your application.
  ///
  /// Alternatively, you can use the published properties of ``Superwall/hasActiveSubscription``
  /// to react to changes as they happen.
  ///
  /// - Note: If you are implementing a ``SubscriptionController`` to handle your apps subscription-related
  /// logic, you should rely on your own logic and not this method.
  ///
  /// - Parameters:
  ///   - newValue: The new value of ``Superwall/hasActiveSubscription``.
  @objc optional func hasActiveSubscriptionDidChange(to newValue: Bool)

  /// Receive all the log messages generated by the SDK.
  ///
  /// - Parameters:
  ///   - level: Specifies the detail of the logs returned from the SDK to the console.
  ///   Can be either `DEBUG`, `INFO`, `WARN`, or `ERROR`, as defined by ``LogLevel``.
  ///   - scope: The possible scope of logs to print to the console, as defined by ``LogScope``.
  ///   - message: The message associated with the log.
  ///   - info: A dictionary of information associated with the log.
  ///   - error: The error associated with the log.
  @MainActor
  @objc optional func handleLog(
    level: String,
    scope: String,
    message: String?,
    info: [String: Any]?,
    error: Swift.Error?
  )
}
