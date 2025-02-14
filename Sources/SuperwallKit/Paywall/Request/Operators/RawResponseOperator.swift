//
//  File.swift
//  
//
//  Created by Yusuf Tör on 23/09/2022.
//

import Combine
import Foundation

extension AnyPublisher where Output == PaywallRequest, Failure == Error {
  func getRawPaywall() -> AnyPublisher<PipelineData, Failure> {
    asyncMap { request in
      await trackResponseStarted(
        paywallId: request.responseIdentifiers.paywallId,
        event: request.eventData,
        sessionEventsManager: request.dependencyContainer.sessionEventsManager
      )
      return request
    }
    .flatMap(getCachedResponseOrLoad)
    .asyncMap {
      let paywallInfo = $0.paywall.getInfo(
        fromEvent: $0.request.eventData,
        sessionEventsManager: $0.request.dependencyContainer.sessionEventsManager
      )
      await trackResponseLoaded(
        paywallInfo,
        event: $0.request.eventData,
        sessionEventsManager: $0.request.dependencyContainer.sessionEventsManager
      )
      return $0
    }
    .eraseToAnyPublisher()
  }

  private func getCachedResponseOrLoad(
    _ request: PaywallRequest
  ) -> AnyPublisher<(paywall: Paywall, request: PaywallRequest), Error> {
    Future {
      let responseLoadStartTime = Date()
      let paywallId = request.responseIdentifiers.paywallId
      let event = request.eventData
      var paywall: Paywall

      do {
        if let staticPaywall = request.dependencyContainer.configManager.getStaticPaywall(withId: paywallId) {
          paywall = staticPaywall
        } else {
          paywall = try await request.dependencyContainer.network.getPaywall(
            withId: paywallId,
            fromEvent: event
          )
        }
      } catch {
        await request.dependencyContainer.sessionEventsManager.triggerSession.trackPaywallResponseLoad(
          forPaywallId: request.responseIdentifiers.paywallId,
          state: .fail
        )
        let errorResponse = PaywallLogic.handlePaywallError(
          error,
          forEvent: event
        )
        throw errorResponse
      }

      paywall.experiment = request.responseIdentifiers.experiment
      paywall.responseLoadingInfo.startAt = responseLoadStartTime
      paywall.responseLoadingInfo.endAt = Date()

      return (paywall, request)
    }
    .eraseToAnyPublisher()
  }

  // MARK: - Analytics
  private func trackResponseStarted(
    paywallId: String?,
    event: EventData?,
    sessionEventsManager: SessionEventsManager
  ) async {
    await sessionEventsManager.triggerSession.trackPaywallResponseLoad(
      forPaywallId: paywallId,
      state: .start
    )
    let trackedEvent = InternalSuperwallEvent.PaywallLoad(
      state: .start,
      eventData: event
    )
    await Superwall.shared.track(trackedEvent)
  }

  private func trackResponseLoaded(
    _ paywallInfo: PaywallInfo,
    event: EventData?,
    sessionEventsManager: SessionEventsManager
  ) async {
    let responseLoadEvent = InternalSuperwallEvent.PaywallLoad(
      state: .complete(paywallInfo: paywallInfo),
      eventData: event
    )
    await Superwall.shared.track(responseLoadEvent)

    await sessionEventsManager.triggerSession.trackPaywallResponseLoad(
      forPaywallId: paywallInfo.databaseId,
      state: .end
    )
  }
}
